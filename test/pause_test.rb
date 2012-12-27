#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class PauseTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_pause_resume
    RubyProf.start
    # Measured
    RubyProf::C1.hello
    RubyProf.pause

    # Not measured
    RubyProf::C1.hello

    RubyProf.resume
    # Measured
    RubyProf::C1.hello
    result = RubyProf.stop

    printer = RubyProf::FlatPrinter.new(result)
    printer.print

    # Length should be 3:
    #   PauseTest#test_pause_resume
    #   <Class::RubyProf::C1>#hello
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check the names
    assert_equal('PauseTest#test_pause_resume', methods[0].full_name)
    assert_equal('<Class::RubyProf::C1>#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.3, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.3, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.3, methods[2].self_time, 0.01)

  end

end
