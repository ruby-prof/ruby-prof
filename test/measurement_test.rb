#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'

class MeasurementTest < Test::Unit::TestCase
  def setup
    # also done in C these days...
    GC.enable_stats if GC.respond_to?(:enable_stats)
  end

  def teardown
    # also done in C for normal runs...
    GC.disable_stats if GC.respond_to?(:disable_stats)
  end

  def test_process_time_mode
    RubyProf::measure_mode = RubyProf::PROCESS_TIME
    assert_equal(RubyProf::PROCESS_TIME, RubyProf::measure_mode)
  end

  def test_process_time
    t = RubyProf.measure_process_time
    assert_kind_of(Float, t)

    u = RubyProf.measure_process_time
    assert(u >= t, [t, u].inspect)
  end

  def test_wall_time_mode
    RubyProf::measure_mode = RubyProf::WALL_TIME
    assert_equal(RubyProf::WALL_TIME, RubyProf::measure_mode)
  end

  def test_wall_time
    t = RubyProf.measure_wall_time
    assert_kind_of Float, t

    u = RubyProf.measure_wall_time
    assert u >= t, [t, u].inspect
  end

  if RubyProf::CPU_TIME
    def test_cpu_time_mode
      RubyProf::measure_mode = RubyProf::CPU_TIME
      assert_equal(RubyProf::CPU_TIME, RubyProf::measure_mode)
    end

    def test_cpu_time
      RubyProf.cpu_frequency = 2.33e9

      t = RubyProf.measure_cpu_time
      assert_kind_of Float, t

      u = RubyProf.measure_cpu_time
      assert u > t, [t, u].inspect
    end
  end

  if RubyProf::ALLOCATIONS
    def test_allocations_mode
      RubyProf::measure_mode = RubyProf::ALLOCATIONS
      assert_equal(RubyProf::ALLOCATIONS, RubyProf::measure_mode)
    end

    def test_allocations
      t = RubyProf.measure_allocations
      assert_kind_of Integer, t

      u = RubyProf.measure_allocations
      assert u > t, [t, u].inspect
    end
  end

  def memory_test_helper
      result = RubyProf.profile {Array.new}
      total = result.threads.values.first.inject(0) { |sum, m| sum + m.total_time }
      assert(total < 1_000_000, 'Total should not have subtract overflow error')
      total
  end

  if RubyProf::MEMORY
    def test_memory_mode
      RubyProf::measure_mode = RubyProf::MEMORY
      assert_equal(RubyProf::MEMORY, RubyProf::measure_mode)
    end

    def test_memory
      t = RubyProf.measure_memory
      assert_kind_of Integer, t

      u = RubyProf.measure_memory
      assert(u >= t, [t, u].inspect)
      RubyProf::measure_mode = RubyProf::MEMORY
      total = memory_test_helper
      assert(total > 0, 'Should measure more than zero kilobytes of memory usage')
      assert_not_equal(0, total % 1, 'Should not truncate fractional kilobyte measurements')
    end
  end

  if RubyProf::GC_RUNS
    def test_gc_runs_mode
      RubyProf::measure_mode = RubyProf::GC_RUNS
      assert_equal(RubyProf::GC_RUNS, RubyProf::measure_mode)
    end

    def test_gc_runs
      t = RubyProf.measure_gc_runs
      assert_kind_of Integer, t

      GC.start

      u = RubyProf.measure_gc_runs
      assert u > t, [t, u].inspect
      RubyProf::measure_mode = RubyProf::GC_RUNS
      memory_test_helper
    end
  end

  if RubyProf::GC_TIME
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
