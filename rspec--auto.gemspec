# frozen_string_literal: true

require_relative "lib/rspec//auto/version"

Gem::Specification.new do |spec|
  spec.name = "rspec--auto"
  spec.version = Rspec::Auto::VERSION
  spec.authors = ["Andrey \"Zed\" Zaikin"]
  spec.email = ["zed.0xff@gmail.com"]

  spec.summary = "Monitor project file changes and run affected specs without reloading all project files"
  spec.description = spec.summary
  spec.homepage = "https://github.com/zed-0xff/rspec--auto"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "listen"
  spec.add_dependency "rb-fsevent"
  spec.add_dependency "warning"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
