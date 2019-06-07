#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureProcessTimeTest < TestCase
  def setup
    # Need to fix this for linux (windows works since PROCESS_TIME is WALL_TIME anyway)
    RubyProf::measure_mode = RubyProf::PROCESS_TIME
    GC.start
  end

  def test_mode
    assert_equal(RubyProf::PROCESS_TIME, RubyProf::measure_mode)
  end

  def test_process_time_enabled_defined
    assert(defined?(RubyProf::PROCESS_TIME_ENABLED))
  end

  def test_class_methods_sleep
    result = RubyProf.profile do
      RubyProf::C1.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods_sleep", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_class_methods_sleep', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('<Class::RubyProf::C1>#sleep_wait', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)
  end

  def test_class_methods_sleep_threaded
    result = RubyProf.profile do
      background_thread = Thread.new do
        RubyProf::C1.sleep_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods_sleep_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('Thread#join', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('<Class::Thread>#new', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Thread#initialize', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    thread = result.threads.last
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods_sleep_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('<Class::RubyProf::C1>#sleep_wait', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)
  end

  def test_class_methods_busy
    result = RubyProf.profile do
      RubyProf::C1.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.1, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods_busy", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_class_methods_busy', methods[0].full_name)
    assert_in_delta(0.1, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.1, methods[0].children_time, 0.02)

    assert_equal('<Class::RubyProf::C1>#busy_wait', methods[1].full_name)
    assert_in_delta(0.1, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.05, methods[1].self_time, 0.02)
    assert_in_delta(0.05, methods[1].children_time, 0.02)

    assert_equal('<Module::Process>#clock_gettime', methods[2].full_name)
    assert_in_delta(0.05, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.05, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)
  end

  def test_class_methods_busy_threaded
    result = RubyProf.profile do
      background_thread = Thread.new do
        RubyProf::C1.busy_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.1, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods_busy_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', methods[0].full_name)
    assert_in_delta(0.1, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.1, methods[0].children_time, 0.02)

    assert_equal('Thread#join', methods[1].full_name)
    assert_in_delta(0.1, methods[1].total_time, 0.02)
    assert_in_delta(0.1, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('<Class::Thread>#new', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Thread#initialize', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    thread = result.threads.last
    assert_in_delta(0.1, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods_busy_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', methods[0].full_name)
    assert_in_delta(0.1, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.1, methods[0].children_time, 0.02)

    assert_equal('<Class::RubyProf::C1>#busy_wait', methods[1].full_name)
    assert_in_delta(0.1, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.05, methods[1].self_time, 0.02)
    assert_in_delta(0.05, methods[1].children_time, 0.02)

    assert_equal('<Module::Process>#clock_gettime', methods[2].full_name)
    assert_in_delta(0.05, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.05, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)
  end

  def test_instance_methods_sleep
    result = RubyProf.profile do
      RubyProf::C1.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('RubyProf::C1#sleep_wait', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.02)
    assert_in_delta(0.0, methods[4].wait_time, 0.02)
    assert_in_delta(0.0, methods[4].self_time, 0.02)
    assert_in_delta(0.0, methods[4].children_time, 0.02)
  end

  def test_instance_methods_sleep_threaded
    result = RubyProf.profile do
      background_thread = Thread.new do
        RubyProf::C1.new.sleep_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('Thread#join', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('<Class::Thread>#new', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Thread#initialize', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    thread = result.threads.last
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('RubyProf::C1#sleep_wait', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.02)
    assert_in_delta(0.0, methods[4].wait_time, 0.02)
    assert_in_delta(0.0, methods[4].self_time, 0.02)
    assert_in_delta(0.0, methods[4].children_time, 0.02)
  end

  def test_instance_methods_busy
    result = RubyProf.profile do
      RubyProf::C1.new.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.2, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods_busy", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_instance_methods_busy', methods[0].full_name)
    assert_in_delta(0.2, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.2, methods[0].children_time, 0.02)

    assert_equal('RubyProf::C1#busy_wait', methods[1].full_name)
    assert_in_delta(0.2, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.09, methods[1].self_time, 0.02)
    assert_in_delta(0.1, methods[1].children_time, 0.02)

    assert_equal('<Module::Process>#clock_gettime', methods[2].full_name)
    assert_in_delta(0.11, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.11, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.02)
    assert_in_delta(0.0, methods[4].wait_time, 0.02)
    assert_in_delta(0.0, methods[4].self_time, 0.02)
    assert_in_delta(0.0, methods[4].children_time, 0.02)
  end

  def test_instance_methods_busy_threaded
    result = RubyProf.profile do
      background_thread = Thread.new do
        RubyProf::C1.new.busy_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(0.2, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods_busy_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', methods[0].full_name)
    assert_in_delta(0.2, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.2, methods[0].children_time, 0.02)

    assert_equal('Thread#join', methods[1].full_name)
    assert_in_delta(0.2, methods[1].total_time, 0.02)
    assert_in_delta(0.2, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('<Class::Thread>#new', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Thread#initialize', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    thread = result.threads.last
    assert_in_delta(0.2, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods_busy_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', methods[0].full_name)
    assert_in_delta(0.2, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.2, methods[0].children_time, 0.02)

    assert_equal('RubyProf::C1#busy_wait', methods[1].full_name)
    assert_in_delta(0.2, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.1, methods[1].self_time, 0.02)
    assert_in_delta(0.1, methods[1].children_time, 0.02)

    assert_equal('<Module::Process>#clock_gettime', methods[2].full_name)
    assert_in_delta(0.1, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.1, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.02)
    assert_in_delta(0.0, methods[4].wait_time, 0.02)
    assert_in_delta(0.0, methods[4].self_time, 0.02)
    assert_in_delta(0.0, methods[4].children_time, 0.02)
  end

  def test_module_methods_sleep
    result = RubyProf.profile do
      RubyProf::C2.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_module_methods_sleep", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_module_methods_sleep', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('RubyProf::M1#sleep_wait', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)
  end

  def test_module_methods_busy
    result = RubyProf.profile do
      RubyProf::C2.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_module_methods_busy", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_module_methods_busy', methods[0].full_name)
    assert_in_delta(0.3, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.3, methods[0].children_time, 0.02)

    assert_equal('RubyProf::M1#busy_wait', methods[1].full_name)
    assert_in_delta(0.3, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.15, methods[1].self_time, 0.02)
    assert_in_delta(0.15, methods[1].children_time, 0.02)

    assert_equal('<Module::Process>#clock_gettime', methods[2].full_name)
    assert_in_delta(0.15, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.15, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)
  end

  def test_module_instance_methods_sleep
    result = RubyProf.profile do
      RubyProf::C2.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_module_instance_methods_sleep", root_methods[0].full_name)

    # Methods called
    #   MeasureProcessTimeTest#test_instance_methods
    #   Class.new
    #   BasicObject#initialize
    #   C1#sleep_wait
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_module_instance_methods_sleep', methods[0].full_name)
    assert_in_delta(0.0, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.0, methods[0].children_time, 0.02)

    assert_equal('RubyProf::M1#sleep_wait', methods[1].full_name)
    assert_in_delta(0.0, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.0, methods[1].self_time, 0.02)
    assert_in_delta(0.0, methods[1].children_time, 0.02)

    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_in_delta(0.0, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.0, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.02)
    assert_in_delta(0.0, methods[4].wait_time, 0.02)
    assert_in_delta(0.0, methods[4].self_time, 0.02)
    assert_in_delta(0.0, methods[4].children_time, 0.02)
  end

  def test_module_instance_methods_busy
    result = RubyProf.profile do
      RubyProf::C2.new.busy_wait
    end
    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open('/Users/cfis/Downloads/graph.html', 'wb') do |file|
      printer.print(file)
    end
    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.02)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureProcessTimeTest#test_module_instance_methods_busy", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    assert_equal('MeasureProcessTimeTest#test_module_instance_methods_busy', methods[0].full_name)
    assert_in_delta(0.3, methods[0].total_time, 0.02)
    assert_in_delta(0.0, methods[0].wait_time, 0.02)
    assert_in_delta(0.0, methods[0].self_time, 0.02)
    assert_in_delta(0.3, methods[0].children_time, 0.02)

    assert_equal('RubyProf::M1#busy_wait', methods[1].full_name)
    assert_in_delta(0.3, methods[1].total_time, 0.02)
    assert_in_delta(0.0, methods[1].wait_time, 0.02)
    assert_in_delta(0.15, methods[1].self_time, 0.02)
    assert_in_delta(0.15, methods[1].children_time, 0.02)

    assert_equal('<Module::Process>#clock_gettime', methods[2].full_name)
    assert_in_delta(0.15, methods[2].total_time, 0.02)
    assert_in_delta(0.0, methods[2].wait_time, 0.02)
    assert_in_delta(0.15, methods[2].self_time, 0.02)
    assert_in_delta(0.0, methods[2].children_time, 0.02)

    assert_equal('Class#new', methods[3].full_name)
    assert_in_delta(0.0, methods[3].total_time, 0.02)
    assert_in_delta(0.0, methods[3].wait_time, 0.02)
    assert_in_delta(0.0, methods[3].self_time, 0.02)
    assert_in_delta(0.0, methods[3].children_time, 0.02)

    assert_equal('BasicObject#initialize', methods[4].full_name)
    assert_in_delta(0.0, methods[4].total_time, 0.02)
    assert_in_delta(0.0, methods[4].wait_time, 0.02)
    assert_in_delta(0.0, methods[4].self_time, 0.02)
    assert_in_delta(0.0, methods[4].children_time, 0.02)
  end
end
