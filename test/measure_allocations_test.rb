#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureAllocationsTest < TestCase
  def test_allocations_mode
    RubyProf::measure_mode = RubyProf::ALLOCATIONS
    assert_equal(RubyProf::ALLOCATIONS, RubyProf::measure_mode)
  end

  def test_allocations_enabled_defined
    assert(defined?(RubyProf::ALLOCATIONS_ENABLED))
  end

  if RubyProf::ALLOCATIONS_ENABLED
    def test_allocations
      t = RubyProf.measure_allocations
      refute_empty("a" + "b")
      u = RubyProf.measure_allocations
      assert_kind_of Integer, t
      assert_kind_of Integer, u
      assert_operator t, :<, u
    end
  end
end
