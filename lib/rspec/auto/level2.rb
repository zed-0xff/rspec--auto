# frozen_string_literal: true
require 'rspec/core'

module RSpec
  module Auto
    def self.level2
      @@level2
    end
    def self.level2= level2
      @@level2 = level2
    end

    class Level2
      def initialize socket, monitored_files, argv
        @argv = argv
        @socket = socket
        @monitored_files = monitored_files
        RSpec::Auto.level2 = self
      end

      def short_path fname
        fname.sub(Dir.pwd+"/","")
      end

      def process_require fname
        if @monitored_files.include?(fname)
          loop do
#            puts "[d] level2 fork (#{short_path(fname)})"
            pid = fork
            if pid && pid > 0
              # parent - infinite loop
              Process.waitpid(pid)
              line = @socket.gets&.strip
              exit! if !line || line == "STOP"
            else
              RSpec.configuration.start_time = ::RSpec::Core::Time.now
              # child - continue normal flow
              @monitored_files.clear
              return
            end
          end
        end
      end

      def loop!
        Kernel.include RequireSpy

        line = @socket.gets&.strip
        if line && line != "STOP"
          RSpec::Core::Runner.run _rspec_args
          # child ends here
          @socket.puts("DONE") rescue Errno::EPIPE
        end
        exit!
      end

      def _rspec_args
        pwd = Dir.pwd
        if (specs=@argv.find_all{ |fname| fname["_spec.rb"] }).any?
          puts "[.] running ONLY #{specs.map(&method(:short_path)).join(' ')}"
          @argv
        elsif @monitored_files.all?{ |fname| fname.end_with?("_spec.rb") }
          puts "[.] running ONLY #{@monitored_files.map(&method(:short_path)).join(' ')}"
          @argv + @monitored_files
        else
          puts "[.] running ALL specs"
          @argv + Dir["spec/**/*_spec.rb"]
        end
      end
    end # class Level2

    module RequireSpy
      def self.included klass
        klass.class_eval do

          alias orig_require require
          def require fname
            return if fname == 'rb-fsevent'
            _process_require fname
            orig_require fname
          end

          def _find_required_file fname
            return fname if fname.start_with?("/") && fname.end_with?(".rb")
            %w'rb so o'.each do |ext|
              fname_rb = "#{fname}.#{ext}"
              return fname_rb if fname.start_with?("/") && File.exist?(fname_rb)
              $:.each do |dirname|
                pathname = File.join(dirname, fname_rb)
                return pathname if File.exist?(File.join(dirname, fname_rb))
              end
            end
            nil
          end

          def _process_require fname
            fname = _find_required_file fname
            RSpec::Auto.level2.process_require(fname)
          end

          alias orig_load load
          def load fname
            return if fname == 'rb-fsevent'
            _process_require fname
            orig_load fname
          end

          alias orig_require_relative require_relative
          def require_relative fname, *args
            pathname = File.join(File.dirname(caller.first.split(":",2)[0]), fname)
            _process_require pathname
            orig_require pathname
          end
        end
      end
    end # module RequireSpy
  end
end
