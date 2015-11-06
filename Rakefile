# encoding: utf-8

require "rubygems/package_task"
require "rake/extensiontask"
require "rake/testtask"
require "rdoc/task"
require "date"
require "rake/clean"
begin
  require "bundler/setup"
  Bundler::GemHelper.install_tasks
rescue LoadError
  $stderr.puts "Install bundler to get support for simplified gem publishing"
end

GEM_NAME = 'ruby-prof'
SO_NAME = 'ruby_prof'

default_spec = Gem::Specification.load("#{GEM_NAME}.gemspec")

# specify which versions/builds to cross compile
Rake::ExtensionTask.new do |ext|
  ext.gem_spec = default_spec
  ext.name = SO_NAME
  ext.ext_dir = "ext/#{SO_NAME}"
  ext.lib_dir = "lib/#{RUBY_VERSION}"
end

# Rake task to build the default package
Gem::PackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
end

task :default => :test

for file in Dir['lib/**/*.{o,so,bundle}']
  CLEAN.include file
end
CLEAN.reject!{|f| !File.exist?(f)}
task :clean do
  # remove tmp dir contents completely after cleaning
  FileUtils.rm_rf('tmp/*')
end

desc 'Run the ruby-prof test suite'
Rake::TestTask.new do |t|
  t.libs += %w(lib ext test)
  t.test_files = Dir['test/**_test.rb']
  t.verbose = true
  t.warning = true
end
