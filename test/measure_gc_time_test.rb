#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureGCTimeTest < Test::Unit::TestCase
  def test_gc_time_mode
    RubyProf::measure_mode = RubyProf::GC_TIME
    assert_equal(RubyProf::GC_TIME, RubyProf::measure_mode)
  end

  def test_gc_time_enabled_defined
    assert(defined?(RubyProf::GC_TIME_ENABLED))
  end

  if RubyProf::GC_TIME_ENABLED
    def test_gc_time
      t = RubyProf.measure_gc_time
      assert_kind_of Integer, t

      GC.start

      u = RubyProf.measure_gc_time
      assert u > t, [t, u].inspect
      RubyProf::measure_mode = RubyProf::GC_TIME
      memory_test_helper
    end
  end
end