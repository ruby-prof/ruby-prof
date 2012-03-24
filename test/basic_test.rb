#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class BasicTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_running
    assert(!RubyProf.running?)
    RubyProf.start
    assert(RubyProf.running?)
    RubyProf.stop
    assert(!RubyProf.running?)
  end

  def test_double_profile
    RubyProf.start
    assert_raise(RuntimeError) do
      RubyProf.start
    end
    RubyProf.stop
  end

  def test_no_block
    assert_raise(ArgumentError) do
      RubyProf.profile
    end
  end

  def test_traceback
    RubyProf.start
    assert_raise(NoMethodError) do
      RubyProf.xxx
    end

    RubyProf.stop
  end
end