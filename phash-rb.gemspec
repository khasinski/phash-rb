# frozen_string_literal: true

require_relative "lib/phash/version"

Gem::Specification.new do |spec|
  spec.name = "phash-rb"
  spec.version = Phash::VERSION
  spec.authors = ["Tomasz Ratajczak", "Krzysztof Hasiński"]
  spec.email = ["twratajczak@gmail.com","krzysztof.hasinski@gmail.com"]

  spec.summary = "Ruby implementation of pHash library"
  spec.description = "Ruby implementation of pHash library, uses VIPS for image processing"
  spec.homepage = "http://github.com/khasinski/phash-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "http://github.com/khasinski/phash-rb"
  spec.metadata["changelog_uri"] = "http://github.com/khasinski/phash-rb"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-vips", "~> 2.0"
  spec.add_dependency "matrix"
  spec.add_dependency "rmagick"
end
