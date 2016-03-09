#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'timeout'
require 'benchmark'

# --  Tests ----
# code for this test taken from ThreadTest and modified
class WhitelistThreadTest < TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_thread_count
    profiler = ::RubyProf::Profile.new(
      RubyProf::WALL_TIME, [], Thread.current
    )
    profiler.start

    thread = Thread.new do
      sleep(1)
    end

    thread.join
    result = profiler.stop
    assert_equal(
      1, result.threads.length, 'only whitelisted thread should show up'
    )
  end

  def test_thread_identity
    profiler = ::RubyProf::Profile.new(
      RubyProf::WALL_TIME, [], Thread.current
    )
    profiler.start

    sleep_thread = Thread.new do
      sleep(1)
    end
    sleep_thread.join
    result = profiler.stop

    thread_ids = result.threads.map {|thread| thread.id}.sort
    assert_equal([Thread.current.object_id], thread_ids)
  end
end
