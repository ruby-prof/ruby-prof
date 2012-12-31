#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class TrickyTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def start
  #  ENV['RUBY_PROF_TRACE']='c:\\temp\\trace.txt'
    RubyProf.start
    sleep 1
  end

  def test_leave_method
    start
    sleep 1
    profile = RubyProf.stop

    # Length should be 3:
    #   MeasureProcessTimeTest#test_class_methods
    #   <Class::RubyProf::C1>#hello
    #   Kernel#sleep

    assert_equal(1, profile.threads.count)

    thread = profile.threads.first
    assert_in_delta(2, thread.total_time, 0.01)

    top_methods = thread.top_methods
    assert_equal(2, top_methods.count)
    assert_equal("TrickyTest#start", top_methods[0].full_name)
    assert_equal("TrickyTest#test_leave_method", top_methods[1].full_name)

    assert_equal(3, thread.methods.length)
    methods = profile.threads.first.methods

    # Check times
    assert_equal("TrickyTest#start", thread.methods[0].full_name)
    assert_in_delta(1.0, methods[0].total_time, 0.01)
    assert_in_delta(0.0, methods[0].wait_time, 0.01)
    assert_in_delta(0.0, methods[0].self_time, 0.01)

    assert_equal("Kernel#sleep", methods[1].full_name)
    assert_in_delta(2.0, methods[1].total_time, 0.01)
    assert_in_delta(0.0, methods[1].wait_time, 0.01)
    assert_in_delta(2.0, methods[1].self_time, 0.01)

    assert_equal("TrickyTest#test_leave_method", methods[2].full_name)
    assert_in_delta(1.0, methods[2].total_time, 0.01)
    assert_in_delta(0.0, methods[2].wait_time, 0.01)
    assert_in_delta(0.0, methods[2].self_time, 0.01)
  end
end
