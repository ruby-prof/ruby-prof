#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_times'

class MeasureProcessTimeTest < TestCase
  def setup
    # Need to fix this for linux (windows works since PROCESS_TIME is WALL_TIME anyway)
    RubyProf::measure_mode = RubyProf::PROCESS_TIME
    GC.start
  end

  def test_mode
    assert_equal(RubyProf::PROCESS_TIME, RubyProf::measure_mode)
  end

  def test_class_methods_sleep
    result = RubyProf.profile do
      RubyProf::C1.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_class_methods_sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
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
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    thread = result.threads.last
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_class_methods_sleep_threaded', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_class_methods_busy
    result = RubyProf.profile do
      RubyProf::C1.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.08, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_class_methods_busy', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.1, method.children_time, 0.05)

    method = methods[1]
    assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.06, method.self_time, 0.05)
    assert_in_delta(0.07, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.05, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.05, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
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
    assert_in_delta(0.1, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.1, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.1, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    thread = result.threads.last
    assert_in_delta(0.1, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_class_methods_busy_threaded', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.1, method.children_time, 0.05)

    method = methods[1]
    assert_equal('<Class::RubyProf::C1>#busy_wait', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.05, method.self_time, 0.05)
    assert_in_delta(0.05, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.05, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.05, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_instance_methods_sleep
    result = RubyProf.profile do
      RubyProf::C1.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::C1#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_instance_methods_sleep_block
    result = RubyProf.profile do
      1.times { RubyProf::C1.new.sleep_wait }
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(6, methods.length)

    # Check times
    method = methods[0]
    assert_equal("MeasureProcessTimeTest#test_instance_methods_sleep_block", method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Integer#times', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('RubyProf::C1#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[5]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
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
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    thread = result.threads.last
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_instance_methods_sleep_threaded', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::C1#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_instance_methods_busy
    result = RubyProf.profile do
      RubyProf::C1.new.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.2, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_instance_methods_busy', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.2, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::C1#busy_wait', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.09, method.self_time, 0.05)
    assert_in_delta(0.11, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.11, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.11, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_instance_methods_busy_block
    result = RubyProf.profile do
      1.times { RubyProf::C1.new.busy_wait }
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(6, methods.length)

    # Check times
    method = methods[0]
    assert_equal("MeasureProcessTimeTest#test_instance_methods_busy_block", method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.2, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Integer#times', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.2, method.children_time, 0.05)

    method = methods[2]
    assert_equal('RubyProf::C1#busy_wait', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.09, method.self_time, 0.05)
    assert_in_delta(0.11, method.children_time, 0.05)

    method = methods[3]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.11, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.11, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[5]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
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
    assert_in_delta(0.2, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.2, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.2, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    thread = result.threads.last
    assert_in_delta(0.2, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_instance_methods_busy_threaded', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.2, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::C1#busy_wait', method.full_name)
    assert_in_delta(0.2, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.1, method.self_time, 0.05)
    assert_in_delta(0.1, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.1, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.1, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_module_methods_sleep
    result = RubyProf.profile do
      RubyProf::C2.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_module_methods_sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::M1#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_module_methods_busy
    result = RubyProf.profile do
      RubyProf::C2.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_module_methods_busy', method.full_name)
    assert_in_delta(0.3, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.3, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::M1#busy_wait', method.full_name)
    assert_in_delta(0.3, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.15, method.self_time, 0.05)
    assert_in_delta(0.15, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.15, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.15, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_module_instance_methods_sleep
    result = RubyProf.profile do
      RubyProf::C2.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_module_instance_methods_sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::M1#sleep_wait', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end

  def test_module_instance_methods_busy
    result = RubyProf.profile do
      RubyProf::C2.new.busy_wait
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.05)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureProcessTimeTest#test_module_instance_methods_busy', method.full_name)
    assert_in_delta(0.3, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.3, method.children_time, 0.05)

    method = methods[1]
    assert_equal('RubyProf::M1#busy_wait', method.full_name)
    assert_in_delta(0.3, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.15, method.self_time, 0.05)
    assert_in_delta(0.15, method.children_time, 0.05)

    method = methods[2]
    assert_equal('<Module::Process>#clock_gettime', method.full_name)
    assert_in_delta(0.15, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.15, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_in_delta(0.0, method.total_time, 0.05)
    assert_in_delta(0.0, method.wait_time, 0.05)
    assert_in_delta(0.0, method.self_time, 0.05)
    assert_in_delta(0.0, method.children_time, 0.05)
  end
end
