#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class GcTest < TestCase
  def some_method
    Array.new(3 * 4)
  end

  def run_profile
    RubyProf.profile do
      self.some_method
    end
  end

  def test_hold_onto_thread
    threads = 1000.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads)
      GC.start
      array
    end

    threads.each do |thread|
      error = assert_raises(RuntimeError) do
        thread.id
      end
      assert_match(/has already been freed/, error.message)
    end
    assert(true)
  end

  def test_hold_onto_root_call_info
    call_trees = 1000.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads.map(&:call_tree))
      GC.start
      array
    end

    call_trees.each do |call_tree|
      error = assert_raises(RuntimeError) do
        call_tree.source_file
      end
      assert_match(/has already been freed/, error.message)
    end
    assert(true)
  end

  def test_hold_onto_method
    methods = 1000.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads.map(&:methods).flatten)
      GC.start
      array
    end

    methods.each do |method|
      error = assert_raises(RuntimeError) do
        method.method_name
      end
      assert_match(/has already been freed/, error.message)
    end
    assert(true)
  end

  def test_hold_onto_call_infos
    method_call_infos = 1000.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads.map(&:methods).flatten.map(&:call_trees).flatten)
      GC.start
      array
    end

    method_call_infos.each do |call_trees|
      error = assert_raises(RuntimeError) do
        call_trees.call_trees
      end
      assert_match(/has already been freed/, error.message)
    end
    assert(true)
  end

  def test_hold_onto_measurements
    measurements = 1000.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads.map(&:methods).flatten.map(&:measurement))
      GC.start
      array
    end

    measurements.each do |measurement|
      error = assert_raises(RuntimeError) do
        measurement.total_time
      end
      assert_match(/has already been freed/, error.message)
    end
    assert(true)
  end
end
