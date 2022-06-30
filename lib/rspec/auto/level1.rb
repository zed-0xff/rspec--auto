# frozen_string_literal: true
require 'socket'
require_relative 'level2'

module RSpec
  module Auto
    class Level1
      def initialize argv=[]
        @pid = nil
        @socket = nil
        @prev_changed_files = nil
        @argv = argv
      end

      def start_child! changed_files
        raise "We're not supposed to have more than one child here" if @pid
        schild, @socket = Socket.pair :UNIX, :STREAM
#        puts "[d] level1 fork"
        @pid = fork do
          @socket.close
          Level2.new(schild, changed_files, @argv).loop!
        end
        schild.close
        Process.detach(@pid)
      end
      
      def child_alive?
        !!Process.kill(0, @pid) rescue false
      end

      def stop!
        stop_child!
      end

      def stop_child!
        return false unless @socket
        @socket.puts("STOP") rescue nil
        @socket.close
        @socket = nil
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        while child_alive?
          t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          if t1-t0 > 1
            puts "[.] waiting for child to stop.."
            sleep 1
          end
          sleep 0.1
        end

        @pid = nil
        true
      end

      def foo changed_files
        changed_files.sort!
        if @prev_changed_files != changed_files
          # restart child telling it to pause at first require of any of changed files
          stop_child! if @pid
          start_child!(changed_files)
        end
        @socket.puts "RUN"
        @socket.gets
        @prev_changed_files = changed_files
      end
    end
  end
end
