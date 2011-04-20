require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'date'

# to release a version of ruby-prof, do a git tag, then rake cleanr default and publish that
# git tag 0.10.1
# git push origin 0.10.1
# rake cleanr default
# gem push pkg/ruby-prof-0.10.1.gem

default_spec = eval File.read(File.expand_path('../ruby-prof.gemspec', __FILE__))

desc 'deprecated--build native .gem files -- use like "native_gems clobber cross native gem"--for non native gem creation use "native_gems clobber" then "clean gem"'
task :native_gems do
  # we don't do cross compiler anymore, now that mingw has devkit
  ENV['RUBY_CC_VERSION'] = '1.8.6:1.9.1'
  require 'rake/extensiontask'
  Rake::ExtensionTask.new('ruby_prof', default_spec) do |ext|
    ext.cross_compile = true
    ext.cross_platform = ['x86-mswin32-60', 'x86-mingw32-60']
  end
end

# Rake task to build the default package
Rake::GemPackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
  #pkg.need_zip = true
end


# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
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

task :default => :package

desc 'Run the ruby-prof test suite'
Rake::TestTask.new do |t|
  t.libs += %w(lib ext test)
  t.test_files = Dir['test/test_suite.rb']
  t.verbose = true
  t.warning = true
end

require 'fileutils'

desc 'Build ruby_prof.so'
task :build do
 Dir.chdir('ext/ruby_prof') do
  unless File.exist? 'Makefile'
    system(Gem.ruby + " extconf.rb")
    system("make clean")
  end
  raise 'make failed' unless system("make")
  FileUtils.cp 'ruby_prof.so', '../../lib' if File.exist? 'lib/ruby_prof.so'
  FileUtils.cp 'ruby_prof.bundle', '../../lib' if File.exist? 'lib/ruby_prof.bundle'
 end
end

desc 'clean stuff'
task :cleanr do
 Dir['**/*.{so,bundle}'].each{|f| File.delete f}
 Dir.chdir('ext/ruby_prof') do
  if File.exist? 'Makefile'
    system("make clean")
    FileUtils.rm 'Makefile'
  end
  Dir.glob('*~') do |file|
    FileUtils.rm file
  end
 end
 system("rm -rf pkg")
end
