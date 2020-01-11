#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_times'

class BasicTest < TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def start
    RubyProf.start
    RubyProf::C1.sleep_wait
  end

  #def test_running
  #  assert(!RubyProf.running?)
  #  RubyProf.start
  #  assert(RubyProf.running?)
  #  RubyProf.stop
  #  assert(!RubyProf.running?)
  #end
  #
  #def test_double_profile
  #  RubyProf.start
  #  assert_raises(RuntimeError) do
  #    RubyProf.start
  #  end
  #  RubyProf.stop
  #end
  #
  #def test_no_block
  #  assert_raises(ArgumentError) do
  #    RubyProf.profile
  #  end
  #end
  #
  #def test_traceback
  #  RubyProf.start
  #  assert_raises(NoMethodError) do
  #    RubyProf.xxx
  #  end
  #
  #  RubyProf.stop
  #end
  #
  #def test_leave_method
  #  start
  #  sleep 0.15
  #  profile = RubyProf.stop
  #
  #  assert_equal(1, profile.threads.count)
  #
  #  thread = profile.threads.first
  #  assert_in_delta(0.25, thread.total_time, 0.05)
  #
  #  assert_equal(4, thread.methods.length)
  #  methods = profile.threads.first.methods.sort
  #
  #  # Check times
  #  assert_equal("<Class::RubyProf::C1>#sleep_wait", methods[0].full_name)
  #  assert_in_delta(0.1, methods[0].total_time, 0.05)
  #  assert_in_delta(0.0,  methods[0].wait_time, 0.05)
  #  assert_in_delta(0.0,  methods[0].self_time, 0.05)
  #
  #  assert_equal("BasicTest#start", methods[1].full_name)
  #  assert_in_delta(0.1, methods[1].total_time, 0.05)
  #  assert_in_delta(0.0, methods[1].wait_time, 0.05)
  #  assert_in_delta(0.0, methods[1].self_time, 0.05)
  #
  #  assert_equal("BasicTest#test_leave_method", methods[2].full_name)
  #  assert_in_delta(0.15, methods[2].total_time, 0.05)
  #  assert_in_delta(0.0, methods[2].wait_time, 0.05)
  #  assert_in_delta(0.0, methods[2].self_time, 0.05)
  #
  #  assert_equal("Kernel#sleep", methods[3].full_name)
  #  assert_in_delta(0.25, methods[3].total_time, 0.05)
  #  assert_in_delta(0.0, methods[3].wait_time, 0.05)
  #  assert_in_delta(0.25, methods[3].self_time, 0.05)
  #end
  #
  #def test_leave_method_2
  #  start
  #  RubyProf::C1.sleep_wait
  #  RubyProf::C1.sleep_wait
  #  profile = RubyProf.stop
  #
  #  assert_equal(1, profile.threads.count)
  #
  #  thread = profile.threads.first
  #  assert_in_delta(0.3, thread.total_time, 0.05)
  #
  #  assert_equal(4, thread.methods.length)
  #  methods = profile.threads.first.methods.sort
  #
  #  # Check times
  #  assert_equal("BasicTest#start", methods[0].full_name)
  #  assert_in_delta(0.1, methods[0].total_time, 0.05)
  #  assert_in_delta(0.0, methods[0].wait_time, 0.05)
  #  assert_in_delta(0.0, methods[0].self_time, 0.05)
  #
  #  assert_equal("BasicTest#test_leave_method_2", methods[1].full_name)
  #  assert_in_delta(0.2, methods[1].total_time, 0.05)
  #  assert_in_delta(0.0, methods[1].wait_time, 0.05)
  #  assert_in_delta(0.0, methods[1].self_time, 0.05)
  #
  #  assert_equal("Kernel#sleep", methods[2].full_name)
  #  assert_in_delta(0.3, methods[2].total_time, 0.05)
  #  assert_in_delta(0.0, methods[2].wait_time, 0.05)
  #  assert_in_delta(0.3, methods[2].self_time, 0.05)
  #
  #  assert_equal("<Class::RubyProf::C1>#sleep_wait", methods[3].full_name)
  #  assert_in_delta(0.3, methods[3].total_time, 0.05)
  #  assert_in_delta(0.0, methods[3].wait_time, 0.05)
  #  assert_in_delta(0.0, methods[3].self_time, 0.05)
  #end

  def test_inline
    profile = RubyProf.profile do
      1.times { RubyProf::C1.new.sleep_wait }
    end

    assert_equal(1, profile.threads.count)

    thread = profile.threads.first
    assert_in_delta(0.2, thread.total_time, 0.05)

    assert_equal(6, thread.methods.length)
    methods = profile.threads.first.methods.sort

    # Check times
    assert_equal("BasicObject#initialize", methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.05)
    assert_in_delta(0.0, methods[0].wait_time, 0.05)
    assert_in_delta(0.0, methods[0].self_time, 0.05)

    assert_equal("Class#new", methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.05)
    assert_in_delta(0.0, methods[1].wait_time, 0.05)
    assert_in_delta(0.0, methods[1].self_time, 0.05)

    assert_equal("Kernel#sleep", methods[2].full_name)
    assert_in_delta(0.2, methods[2].total_time, 0.05)
    assert_in_delta(0.0, methods[2].wait_time, 0.05)
    assert_in_delta(0.2, methods[2].self_time, 0.05)

    assert_equal("RubyProf::C1#sleep_wait", methods[3].full_name)
    assert_in_delta(0.2, methods[3].total_time, 0.05)
    assert_in_delta(0.0, methods[3].wait_time, 0.05)
    assert_in_delta(0.0, methods[3].self_time, 0.05)

    assert_equal("Integer#times", methods[4].full_name)
    assert_in_delta(0.2, methods[4].total_time, 0.05)
    assert_in_delta(0.0, methods[4].wait_time, 0.05)
    assert_in_delta(0.0, methods[4].self_time, 0.05)

    assert_equal("BasicTest#test_inline", methods[5].full_name)
    assert_in_delta(0.2, methods[5].total_time, 0.05)
    assert_in_delta(0.0, methods[5].wait_time, 0.05)
    assert_in_delta(0.0, methods[5].self_time, 0.05)
  end
end
