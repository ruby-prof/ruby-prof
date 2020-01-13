#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class GcTest < TestCase
  def setup
    GC.stress = true
  end

  def teardown
    GC.stress = false
  end

  def some_method
    Array.new(3 * 4)
  end

  def run_profile
    RubyProf.profile do
      self.some_method
    end
  end

  def test_hold_onto_thread
    threads = 5.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads)
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
    call_trees = 5.times.reduce(Array.new) do |array, i|
      array.concat(run_profile.threads.map(&:call_tree))
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
    methods = 5.times.reduce(Array.new) do |array, i|
      profile = run_profile
      methods_2 = profile.threads.map(&:methods).flatten
      array.concat(methods_2)
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

  def test_hold_onto_call_trees
    method_call_infos = 5.times.reduce(Array.new) do |array, i|
      profile = run_profile
      call_trees = profile.threads.map(&:methods).flatten.map(&:call_trees).flatten
      array.concat(call_trees)
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
    measurements = 5.times.reduce(Array.new) do |array, i|
      profile = run_profile
      measurements = profile.threads.map(&:methods).flatten.map(&:measurement)
      array.concat(measurements)
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
