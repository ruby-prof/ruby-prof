# encoding: utf-8

require "rubygems/package_task"
require "rake/extensiontask"
require "rake/testtask"
require "rdoc/task"
require "date"
require "rake/clean"
begin
  require "bundler/setup"
  require "bundler"
  Bundler::GemHelper.install_tasks
  [:build, :install, :release].each {|t| Rake::Task[t].enhance [:rdoc] }
rescue LoadError
  $stderr.puts "Install bundler to get support for simplified gem publishing"
end

# To release a version of ruby-prof:
#   * Update version.h
#   * Update CHANGES
#   * git commit to commit files
#   * rake clobber to remove extra files
#   * rake compile to build windows gems
#   * rake package to create the gems
#   * Tag the release (git tag 0.10.1)
#   * Push to ruybgems.org (gem push pkg/<gem files>)
# For a ruby only release, just run
#   * rake release
# it will push changes to github, tag the release, build the package and upload it to rubygems.org
# and in case you forgot to increment the version number or have uncommitted changes, it will refuse to work

GEM_NAME = 'ruby-prof'
SO_NAME = 'ruby_prof'

default_spec = Gem::Specification.load("#{GEM_NAME}.gemspec")

# specify which versions/builds to cross compile
Rake::ExtensionTask.new do |ext|
  ext.gem_spec = default_spec
  ext.name = SO_NAME
  ext.ext_dir = "ext/#{SO_NAME}"
  ext.lib_dir = "lib/#{RUBY_VERSION.sub(/\.\d$/, '')}"
  ext.cross_compile = true
  ext.cross_platform = ['x86-mswin32-60', 'x86-mingw32-60']
end

# Rake task to build the default package
Gem::PackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
end

# make sure rdoc has been built when packaging
# why do we ship rdoc as part of the gem?
Rake::Task[:package].enhance [:rdoc]

# Setup Windows Gem
if RUBY_PLATFORM.match(/win32|mingw32/)
  # Windows specification
  win_spec = default_spec.clone
  win_spec.platform = Gem::Platform::CURRENT
  win_spec.files += Dir.glob('lib/**/*.so')
  win_spec.instance_variable_set(:@cache_file, nil) # Hack to work around gem issue

  # Unset extensions
  win_spec.extensions = nil

  # Rake task to build the windows package
  Gem::PackageTask.new(win_spec) do |pkg|
    pkg.need_tar = false
  end
end

# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
RDoc::Task.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "ruby-prof"
  # Show source inline with line numbers
  rdoc.options << "--inline-source" << "--line-numbers"
  # Make the readme file the start page for the generated html
  rdoc.options << '--main' << 'README.rdoc'
  rdoc.rdoc_files.include('bin/**/*',
                          'doc/*.rdoc',
                          'examples/flat.txt',
                          'examples/graph.txt',
                          'examples/graph.html',
                          'lib/**/*.rb',
                          'ext/ruby_prof/ruby_prof.c',
                          'ext/ruby_prof/version.h',
                          'ext/ruby_prof/measure_*.h',
                          'README.rdoc',
                          'LICENSE')
end

task :default => :test

for file in Dir['**/*.{o,so,bundle}']
  CLEAN.include file
end

for file in Dir['tmp/*.{txt,dat,png,html}']
  CLEAN.include file
end

desc 'Run the ruby-prof test suite'
Rake::TestTask.new do |t|
  t.libs += %w(lib ext test)
  t.test_files = Dir['test/test_suite.rb']
  t.verbose = true
  t.warning = true
end
