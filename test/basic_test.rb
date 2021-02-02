#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_times'

class BasicTest < TestCase
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
    assert_raises(RuntimeError) do
      RubyProf.start
    end
    RubyProf.stop
  end

  def test_no_block
    assert_raises(ArgumentError) do
      RubyProf.profile
    end
  end

  def test_traceback
    RubyProf.start
    assert_raises(NoMethodError) do
      RubyProf.xxx
    end

    RubyProf.stop
  end
end
