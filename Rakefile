require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'date'

# ------- Version ----
# Read version from header file
version_header = File.read('ext/version.h')
match = version_header.match(/RUBY_PROF_VERSION\s*["](\d.+)["]/)
raise(RuntimeError, "Could not determine RUBY_PROF_VERSION") if not match
RUBY_PROF_VERSION = match[1]
  

# ------- Default Package ----------
FILES = FileList[
  'Rakefile',
  'README',
  'LICENSE',
  'CHANGES',
  'bin/*',
  'doc/**/*',
  'examples/*',
  'ext/*',
  'ext/mingw/Rakefile',
  'ext/mingw/build.rake',
  'ext/vc/*.sln',
  'ext/vc/*.vcproj',
  'lib/**/*',
  'rails/**/*',
  'test/*'
]

# Default GEM Specification
default_spec = Gem::Specification.new do |spec|
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

  spec.author = "Shugo Maeda and Charlie Savage"
  spec.email = "shugo@ruby-lang.org and cfis@savagexi.com"
  spec.platform = Gem::Platform::RUBY
  spec.require_path = "lib" 
  spec.bindir = "bin"
  spec.executables = ["ruby-prof"]
  spec.extensions = ["ext/extconf.rb"]
  spec.files = FILES.to_a
  spec.test_files = Dir["test/test_*.rb"]
  

  spec.required_ruby_version = '>= 1.8.4'
  spec.date = DateTime.now
  spec.rubyforge_project = 'ruby-prof'
  
  # rdoc
  spec.has_rdoc = true
end

# Rake task to build the default package
Rake::GemPackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
  #pkg.need_zip = true
end


# ------- Windows Package ----------
if RUBY_PLATFORM.match(/win32/)
  binaries = (FileList['ext/mingw/*.so',
                       'ext/mingw/*.dll*'])

  # Windows specification
  win_spec = default_spec.clone
  win_spec.extensions = ['ext/mingw/Rakefile']
  win_spec.platform = Gem::Platform::CURRENT
  win_spec.files += binaries.to_a

  # Rake task to build the windows package
  Rake::GemPackageTask.new(win_spec) do |pkg|
  end
end

# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "ruby-prof"
  # Show source inline with line numbers
  rdoc.options << "--inline-source" << "--line-numbers"
  # Make the readme file the start page for the generated html
  rdoc.options << '--main' << 'README'
  rdoc.rdoc_files.include('bin/**/*',
                          'doc/*.rdoc',
                          'examples/flat.txt',
                          'examples/graph.txt',
                          'examples/graph.html',
                          'lib/**/*.rb',
                          'ext/ruby_prof.c',
                          'ext/version.h',
                          'ext/measure_*.h',
                          'README',
                          'LICENSE')
end

task :default => :package

desc 'Run the ruby-prof test suite'
Rake::TestTask.new do |t|
  t.libs += %w(lib ext test)
  t.test_files = Dir['test/test_suite.rb']
  t.verbose = true
  t.warning = true
end