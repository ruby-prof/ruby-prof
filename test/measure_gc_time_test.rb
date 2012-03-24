#!/usr/bin/env ruby
# encoding: UTF-8

require './test_helper'

if RubyProf::GC_TIME_ENABLED
  class MeasureGCTimeTest < Test::Unit::TestCase
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