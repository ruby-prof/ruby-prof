#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class FakeRackApp
  def call(env)
  end
end

module Rack
  class Request
    def initialize(env)
      if env == :fake_env
        @env = {}
      else
        @env = env
      end
    end

    def path
      @env[:path] || '/path/to/resource.json'
    end
  end
end

module Rack
  class RubyProf
    attr_reader :_profiler

    def public_delete_profiler!
      delete_profiler!
    end
  end
end

class RackTest < TestCase
  def test_create_print_path
    path = Dir.mktmpdir
    Dir.delete(path)

    Rack::RubyProf.new(FakeRackApp.new, :path => path)

    assert(Dir.exist?(path))
  end

  def test_create_profile_reports
    path = Dir.mktmpdir

    adapter = Rack::RubyProf.new(FakeRackApp.new, :path => path)

    adapter.call(:fake_env)

    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "path-to-resource.json-#{base_name}")
      assert(File.exist?(file_path))
    end
  end

  def test_skip_paths
    path = Dir.mktmpdir

    adapter = Rack::RubyProf.new(FakeRackApp.new, :path => path, :skip_paths => [%r{\.json$}])

    adapter.call(:fake_env)

    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "path-to-resource.json-#{base_name}")
      assert(!File.exist?(file_path))
    end
  end

  def test_only_paths
    path = Dir.mktmpdir

    adapter = Rack::RubyProf.new(FakeRackApp.new, :path => path, :only_paths => [%r{\.json$}])

    adapter.call({path: '/path/to/resource.json'})

    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "path-to-resource.json-#{base_name}")
      assert(File.exist?(file_path))
    end

    adapter.call({path: '/path/to/resource.html'})
    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "path-to-resource.html-#{base_name}")
      assert(!File.exist?(file_path))
    end
  end

  def test_allows_lazy_filename_setting
    path = Dir.mktmpdir

    printer = {::RubyProf::FlatPrinter => lambda { 'dynamic.txt' }}
    adapter = Rack::RubyProf.new(FakeRackApp.new, :path => path, :printers => printer)

    adapter.call(:fake_env)

    file_path = ::File.join(path, 'path-to-resource.json-dynamic.txt')
    assert(File.exist?(file_path))
  end

  def test_works_for_multiple_requests
    path = Dir.mktmpdir

    adapter = Rack::RubyProf.new(FakeRackApp.new, :path => path, :max_requests => 2)

    # make a 1st request, and check that this didn't create any files
    adapter.call(:fake_env)
    assert(Dir["#{path}/*"].empty?)

    # now a second request should create all the expected files
    adapter.call(:fake_env)
    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "multi-requests-2-#{base_name}")
      assert(File.exist?(file_path))
    end

    # let's clean up
    FileUtils.rm_rf(Dir["#{path}/*"])

    # and do the same again for the next 2 requests
    adapter.call(:fake_env)
    assert(Dir["#{path}/*"].empty?)

    adapter.call(:fake_env)
    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "multi-requests-2-#{base_name}")
      assert(File.exist?(file_path))
    end
  end

  def test_tries_to_print_results_if_shut_down_before_max_requests_reached
    path = Dir.mktmpdir

    adapter = Rack::RubyProf.new(FakeRackApp.new, :path => path, :max_requests => 100)

    # make a 1st request, and check that this didn't create any files
    adapter.call(:fake_env)
    assert(Dir["#{path}/*"].empty?)

    adapter.public_delete_profiler!

    %w(flat.txt graph.txt graph.html call_stack.html).each do |base_name|
      file_path = ::File.join(path, "multi-requests-1-#{base_name}")
      assert(File.exist?(file_path))
    end
  end

  def test_it_uses_separate_profilers_if_not_aggregating_multiple_requests
    adapter1 = Rack::RubyProf.new(FakeRackApp.new)
    adapter2 = Rack::RubyProf.new(FakeRackApp.new)

    assert(adapter1.object_id != adapter2.object_id)
  end
end
