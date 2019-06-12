#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureAllocationsTest < TestCase
  def setup
    RubyProf::measure_mode = RubyProf::ALLOCATIONS
  end

  def test_allocations_mode
    RubyProf::measure_mode = RubyProf::ALLOCATIONS
    assert_equal(RubyProf::ALLOCATIONS, RubyProf::measure_mode)
  end

  def test_class_methods
    result = RubyProf.profile do
      RubyProf::C1.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(6, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_class_methods", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check the names
    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_class_methods', method.full_name)
    assert_in_delta(6, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_in_delta(4, method.children_time, 1)

    method = methods[1]
    assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
    assert_in_delta(4, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_in_delta(2, method.self_time, 1)
    assert_equal(2, method.children_time)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_class_methods_threaded
    result = RubyProf.profile do
      background_thread = Thread.new do
        RubyProf::C1.sleep_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(25, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_class_methods_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_class_methods_threaded', method.full_name)
    assert_in_delta(25, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_in_delta(23, method.children_time, 1)

    method = methods[1]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_equal(12, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(4, method.self_time)
    assert_equal(8, method.children_time)

    method = methods[2]
    assert_equal('Thread#join', method.full_name)
    assert_equal(11, method.total_time)
    assert_equal(9, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_equal(8, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(8, method.self_time)
    assert_equal(0, method.children_time)

    thread = result.threads.last
    assert_equal(9, thread.total_time)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_class_methods_threaded', method.full_name)
    assert_equal(9, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(5, method.self_time)
    assert_equal(4, method.children_time)

    method = methods[1]
    assert_equal('<Class::RubyProf::C1>#sleep_wait', method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_instance_methods
    result = RubyProf.profile do
      RubyProf::C1.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(11, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_instance_methods", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_instance_methods',  method.full_name)
    assert_in_delta(11, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_in_delta(9, method.children_time, 1)

    method = methods[1]
    assert_equal('Class#new', method.full_name)
    assert_equal(5, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(3, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[2]
    assert_equal('RubyProf::C1#sleep_wait',  method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[3]
    assert_equal('Kernel#sleep',  method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[4]
    assert_equal('BasicObject#initialize',  method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_instance_methods_block
    result = RubyProf.profile do
      1.times { RubyProf::C1.new.sleep_wait }
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(6, methods.length)

    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_instance_methods_block',  method.full_name)
    assert_in_delta(13, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_in_delta(11, method.children_time, 1)

    method = methods[1]
    assert_equal('Integer#times', method.full_name)
    assert_in_delta(12, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_in_delta(10, method.children_time, 1)

    method = methods[2]
    assert_equal('Class#new', method.full_name)
    assert_equal(5, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(3, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[3]
    assert_equal('RubyProf::C1#sleep_wait',  method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[4]
    assert_equal('Kernel#sleep',  method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[5]
    assert_equal('BasicObject#initialize',  method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_instance_methods_threaded
    result = RubyProf.profile do
      background_thread = Thread.new do
        RubyProf::C1.new.sleep_wait
      end
      background_thread.join
    end

    assert_equal(2, result.threads.count)

    thread = result.threads.first
    assert_in_delta(30, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_instance_methods_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_instance_methods_threaded', method.full_name)
    assert_in_delta(30, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_in_delta(28, method.children_time, 1)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_equal(16, method.total_time)
    assert_equal(14, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_equal(12, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(4, method.self_time)
    assert_equal(8, method.children_time)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_equal(8, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(8, method.self_time)
    assert_equal(0, method.children_time)

    thread = result.threads.last
    assert_equal(14, thread.total_time)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_instance_methods_threaded", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    methods = result.threads.last.methods.sort.reverse
    assert_equal(5, methods.length)

    # Check times
    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_instance_methods_threaded', method.full_name)
    assert_equal(14, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(5, method.self_time)
    assert_equal(9, method.children_time)

    method = methods[1]
    assert_equal('Class#new', method.full_name)
    assert_equal(5, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(3, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[2]
    assert_equal('RubyProf::C1#sleep_wait', method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_module_methods
    result = RubyProf.profile do
      RubyProf::C2.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(7, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_module_methods", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_module_methods', method.full_name)
    assert_in_delta(7, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_in_delta(3, method.self_time, 1)
    assert_in_delta(4, method.children_time, 1)

    method = methods[1]
    assert_equal('RubyProf::M1#sleep_wait', method.full_name)
    assert_in_delta(4, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_in_delta(3, method.self_time, 1)
    assert_equal(2, method.children_time)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_module_instance_methods
    result = RubyProf.profile do
      RubyProf::C2.new.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(12, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_module_instance_methods", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_module_instance_methods', method.full_name)
    assert_in_delta(12, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_in_delta(3, method.self_time, 1)
    assert_in_delta(9, method.children_time, 1)

    method = methods[1]
    assert_equal('Class#new', method.full_name)
    assert_equal(5, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(3, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[2]
    assert_equal('RubyProf::M1#sleep_wait', method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[4]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
  end

  def test_singleton_methods
    result = RubyProf.profile do
      RubyProf::C3.instance.sleep_wait
    end

    thread = result.threads.first
    assert_in_delta(16, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTest#test_singleton_methods", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(7, methods.length)

    method = methods[0]
    assert_equal('MeasureAllocationsTest#test_singleton_methods', method.full_name)
    assert_in_delta(15, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(13, method.children_time)

    method = methods[1]
    assert_equal('<Class::RubyProf::C3>#instance', method.full_name)
    assert_equal(9, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(7, method.children_time)

    method = methods[2]
    assert_equal('Thread::Mutex#synchronize', method.full_name)
    assert_equal(7, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(5, method.children_time)

    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_equal(5, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(3, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[4]
    assert_equal('RubyProf::C3#sleep_wait', method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(2, method.children_time)

    method = methods[5]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)

    method = methods[6]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_equal(2, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(2, method.self_time)
    assert_equal(0, method.children_time)
    end
end
