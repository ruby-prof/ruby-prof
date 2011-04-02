# -*- encoding: utf-8 -*-

# Read version from header file
version_header = File.read(File.expand_path('../ext/ruby_prof/version.h', __FILE__))
match = version_header.match(/RUBY_PROF_VERSION\s*["](\d.+)["]/)
raise(RuntimeError, "Could not determine RUBY_PROF_VERSION") if not match
RUBY_PROF_VERSION = match[1]

Gem::Specification.new do |spec|
  spec.name = "ruby-prof"

  spec.homepage = "http://rubyforge.org/projects/ruby-prof/"
  spec.summary = "Fast Ruby profiler"
  spec.description = <<-EOF
ruby-prof is a fast code profiler for Ruby. It is a C extension and
therefore is many times faster than the standard Ruby profiler. It
supports both flat and graph profiles.  For each method, graph profiles
show how long the method ran, which methods called it and which
methods it called. RubyProf generate both text and html and can output
it to standard out or to a file.
EOF

  spec.version = RUBY_PROF_VERSION

  spec.author = "Shugo Maeda, Charlie Savage, Roger Pack, Stefan Kaes"
  spec.email = "shugo@ruby-lang.org, cfis@savagexi.com, rogerdpack@gmail.com, skaes@railsexpress.de"
  spec.platform = Gem::Platform::RUBY
  spec.require_path = "lib"
  spec.bindir = "bin"
  spec.executables = ["ruby-prof"]
  spec.extensions = ["ext/ruby_prof/extconf.rb"]
  spec.files = Dir['Rakefile',
                   'README.rdoc',
                   'LICENSE',
                   'CHANGES',
                   'bin/*',
                   'doc/**/*',
                   'examples/*',
                   'ext/ruby_prof/*.c',
                   'ext/ruby_prof/*.h',
                   'ext/ruby_prof/mingw/Rakefile',
                   'ext/ruby_prof/mingw/build.rake',
                   'ext/vc/*.sln',
                   'ext/vc/*.vcproj',
                   'lib/**/*',
                   'rails/**/*',
                   'test/*']

  spec.test_files = Dir["test/test_*.rb"]
  spec.required_ruby_version = '>= 1.8.4'
  spec.date = DateTime.now
  spec.rubyforge_project = 'ruby-prof'
  spec.add_development_dependency 'os'
  spec.add_development_dependency 'rake-compiler'

end
