#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureCpuTimeTest < TestCase
  def setup
    RubyProf::measure_mode = RubyProf::CPU_TIME
  end

  def teardown
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_mode
    assert_equal(RubyProf::CPU_TIME, RubyProf::measure_mode)
  end

  def test_cpu_time_enabled_defined
    assert(defined?(RubyProf::CPU_TIME_ENABLED))
  end

  def test_class_methods
    result = RubyProf.profile do
      RubyProf::C7.busy_wait
    end

    # Length should be greater 2:
    #   MeasureCpuTimeTest#test_class_methods
    #   <Class::RubyProf::C1>#busy_wait
    #   ....

    methods = result.threads.first.methods.sort.reverse[0..1]
    assert_equal(2, methods.length)

    # Check the names
    assert_equal('MeasureCpuTimeTest#test_class_methods', methods[0].full_name)
    assert_equal('<Class::RubyProf::C7>#busy_wait', methods[1].full_name)

    # Check times
    assert_in_delta(0.1, methods[0].total_time, 0.05)
    assert_in_delta(0, methods[0].wait_time, 0.05)
    assert_in_delta(0, methods[0].self_time, 0.05)

    assert_in_delta(0.1, methods[1].total_time, 0.05)
    assert_in_delta(0, methods[1].wait_time, 0.05)
    assert_in_delta(0, methods[1].self_time, 0.05)
  end

  def test_instance_methods
    result = RubyProf.profile do
      RubyProf::C7.new.busy_wait
    end

    methods = result.threads.first.methods.sort.reverse[0..1]
    assert_equal(2, methods.length)

    # Methods at this point:
    #   MeasureCpuTimeTest#test_instance_methods
    #   C7#busy_wait
    #   ...

    names = methods.map(&:full_name)
    assert_equal('MeasureCpuTimeTest#test_instance_methods', names[0])
    assert_equal('RubyProf::C7#busy_wait', names[1])


    # Check times
    assert_in_delta(0.2, methods[0].total_time, 0.03)
    assert_in_delta(0, methods[0].wait_time, 0.03)
    assert_in_delta(0, methods[0].self_time, 0.03)

    assert_in_delta(0.2, methods[1].total_time, 0.03)
    assert_in_delta(0, methods[1].wait_time, 0.03)
    assert_in_delta(0, methods[1].self_time, 0.2)
  end

  def test_module_methods
    result = RubyProf.profile do
      RubyProf::C8.busy_wait
    end

    # Methods:
    #   MeasureCpuTimeTest#test_module_methods
    #   M1#busy_wait
    #   ...

    methods = result.threads.first.methods.sort.reverse[0..1]
    assert_equal(2, methods.length)

    assert_equal('MeasureCpuTimeTest#test_module_methods', methods[0].full_name)
    assert_equal('RubyProf::M7#busy_wait', methods[1].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0.3, methods[1].total_time, 0.1)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.1)
  end

  def test_module_instance_methods
    result = RubyProf.profile do
      RubyProf::C8.new.busy_wait
    end

    # Methods:
    #   MeasureCpuTimeTest#test_module_instance_methods
    #   M7#busy_wait
    #   ...

    methods = result.threads.first.methods.sort.reverse[0..1]
    assert_equal(2, methods.length)
    names = methods.map(&:full_name)
    assert_equal('MeasureCpuTimeTest#test_module_instance_methods', names[0])
    assert_equal('RubyProf::M7#busy_wait', names[1])

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.1)
    assert_in_delta(0, methods[0].self_time, 0.1)

    assert_in_delta(0.3, methods[1].total_time, 0.1)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.1)
  end

  def test_singleton
    c3 = RubyProf::C3.new

    class << c3
      def busy_wait
      end
    end

    result = RubyProf.profile do
      c3.busy_wait
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(2, methods.length)

    assert_equal('MeasureCpuTimeTest#test_singleton', methods[0].full_name)
    assert_equal('<Object::RubyProf::C3>#busy_wait', methods[1].full_name)

    assert_in_delta(0, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)
  end


  def test_sleeping_does_accumulate_wall_time
    RubyProf::measure_mode = RubyProf::WALL_TIME
    result = RubyProf.profile do
      sleep 0.1
    end
    methods = result.threads.first.methods.sort.reverse
    assert_equal(["MeasureCpuTimeTest#test_sleeping_does_accumulate_wall_time", "Kernel#sleep"], methods.map(&:full_name))
    assert_in_delta(0.1, methods[1].total_time, 0.01)
    assert_equal(0, methods[1].wait_time)
    assert_in_delta(0.1, methods[1].self_time, 0.01)
  end

  def test_sleeping_does_not_accumulate_significant_cpu_time
    result = RubyProf.profile do
      sleep 0.1
    end
    methods = result.threads.first.methods.sort.reverse
    assert_equal(["MeasureCpuTimeTest#test_sleeping_does_not_accumulate_significant_cpu_time", "Kernel#sleep"], methods.map(&:full_name))
    assert_in_delta(0, methods[1].total_time, 0.01)
    assert_equal(0, methods[1].wait_time)
    assert_in_delta(0, methods[1].self_time, 0.01)
  end

  def test_waiting_for_threads_does_not_accumulate_cpu_time
    background_thread = nil
    result = RubyProf.profile do
      background_thread = Thread.new{ sleep 0.1 }
      background_thread.join
    end
    # check number of threads
    assert_equal(2, result.threads.length)
    fg, bg = result.threads
    assert(fg.methods.map(&:full_name).include?("Thread#join"))
    assert(bg.methods.map(&:full_name).include?("Kernel#sleep"))
    assert_in_delta(0, fg.total_time, 0.01)
    assert_in_delta(0, bg.total_time, 0.01)
  end

  def test_waiting_for_threads_does_accumulate_wall_time
    RubyProf::measure_mode = RubyProf::WALL_TIME
    background_thread = nil
    result = RubyProf.profile do
      background_thread = Thread.new{ sleep 0.1 }
      background_thread.join
    end
    # check number of threads
    assert_equal(2, result.threads.length)
    fg, bg = result.threads
    assert(fg.methods.map(&:full_name).include?("Thread#join"))
    assert(bg.methods.map(&:full_name).include?("Kernel#sleep"))
    assert_in_delta(0.1, fg.total_time, 0.01)
    assert_in_delta(0.1, fg.wait_time, 0.01)
    assert_in_delta(0.1, bg.total_time, 0.01)
  end

end
