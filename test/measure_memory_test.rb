#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureMemoryTest < TestCase
  def setup
    RubyProf::measure_mode = RubyProf::MEMORY
  end

  def test_memory_mode
    RubyProf::measure_mode = RubyProf::MEMORY
    assert_equal(RubyProf::ALLOCATIONS, RubyProf::measure_mode)
  end

  # def test_class_methods
  #   result = RubyProf.profile do
  #     RubyProf::C1.sleep_wait
  #   end
  #
  #   thread = result.threads.first
  #   assert_equal(7, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_class_methods", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(3, methods.length)
  #
  #   # Check the names
  #   assert_equal('MeasureMemoryTest#test_class_methods', methods[0].full_name)
  #   assert_equal('<Class::RubyProf::C1>#sleep_wait', methods[1].full_name)
  #   assert_equal('Kernel#sleep', methods[2].full_name)
  #
  #   # Check times
  #   assert_equal(7, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(2, methods[0].self_time)
  #
  #   assert_equal(4, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(2, methods[1].self_time)
  #
  #   assert_equal(2, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(0.1, methods[2].self_time)
  # end
  #
  # def test_class_methods_threaded
  #   result = RubyProf.profile do
  #     background_thread = Thread.new do
  #       RubyProf::C1.sleep_wait
  #     end
  #     background_thread.join
  #   end
  #
  #   assert_equal(2, result.threads.count)
  #
  #   thread = result.threads.first
  #   assert_equal(25, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_class_methods_threaded", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(4, methods.length)
  #
  #   # Check times
  #   assert_equal('MeasureMemoryTest#test_class_methods_threaded', methods[0].full_name)
  #   assert_equal(25, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(2, methods[0].self_time)
  #   assert_equal(23, methods[0].children_time)
  #
  #   assert_equal('<Class::Thread>#new', methods[1].full_name)
  #   assert_equal(11, methods[2].total_time)
  #   assert_equal(9, methods[2].wait_time)
  #   assert_equal(2, methods[2].self_time)
  #   assert_equal(0, methods[2].children_time)
  #
  #   assert_equal('Thread#join', methods[2].full_name)
  #   assert_equal(12, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(4, methods[1].self_time)
  #   assert_equal(8, methods[1].children_time)
  #
  #   assert_equal('Thread#initialize', methods[3].full_name)
  #   assert_equal(8, methods[3].total_time)
  #   assert_equal(0, methods[3].wait_time)
  #   assert_equal(8, methods[3].self_time)
  #   assert_equal(0, methods[3].children_time)
  #
  #   thread = result.threads.last
  #   assert_equal(9, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_class_methods_threaded", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(4, methods.length)
  #
  #   methods = result.threads.last.methods.sort.reverse
  #   assert_equal(3, methods.length)
  #
  #   # Check times
  #   assert_equal('MeasureMemoryTest#test_class_methods_threaded', methods[0].full_name)
  #   assert_equal(0.1, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(0, methods[0].self_time)
  #   assert_equal(0.1, methods[0].children_time)
  #
  #   assert_equal('<Class::RubyProf::C1>#sleep_wait', methods[1].full_name)
  #   assert_equal(0.1, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(0, methods[1].self_time)
  #   assert_equal(0.1, methods[1].children_time)
  #
  #   assert_equal('Kernel#sleep', methods[2].full_name)
  #   assert_equal(0.1, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(0.1, methods[2].self_time)
  #   assert_equal(0, methods[2].children_time)
  # end
  # #
  # def test_instance_methods
  #   result = RubyProf.profile do
  #     RubyProf::C1.new.sleep_wait
  #   end
  #
  #   thread = result.threads.first
  #   assert_equal(11, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_instance_methods", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(5, methods.length)
  #   names = methods.map(&:full_name)
  #   assert_equal('MeasureMemoryTest#test_instance_methods', names[0])
  #   assert_equal('Class#new', names[1])
  #   assert_equal('RubyProf::C1#sleep_wait', names[2])
  #   assert_equal('Kernel#sleep', names[3])
  #
  #   # order can differ
  #   assert(names.include?("BasicObject#initialize"))
  #
  #   # Check times
  #   assert_equal(11, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(2, methods[0].self_time)
  #
  #   assert_equal(5, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(3, methods[1].self_time)
  #
  #   assert_equal(4, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(2, methods[2].self_time)
  #
  #   assert_equal(2, methods[3].total_time)
  #   assert_equal(0, methods[3].wait_time)
  #   assert_equal(2, methods[3].self_time)
  #
  #   assert_equal(2, methods[4].total_time)
  #   assert_equal(0, methods[4].wait_time)
  #   assert_equal(2, methods[4].self_time)
  # end
  #
  # def test_instance_methods_threaded
  #   result = RubyProf.profile do
  #     background_thread = Thread.new do
  #       RubyProf::C1.new.sleep_wait
  #     end
  #     background_thread.join
  #   end
  #
  #   assert_equal(2, result.threads.count)
  #
  #   thread = result.threads.first
  #   assert_equal(31, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_instance_methods_threaded", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(4, methods.length)
  #
  #   # Check times
  #   assert_equal('MeasureMemoryTest#test_instance_methods_threaded', methods[0].full_name)
  #   assert_equal(30, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(2, methods[0].self_time)
  #   assert_equal(28, methods[0].children_time)
  #
  #   assert_equal('Thread#join', methods[1].full_name)
  #   assert_equal(16, methods[1].total_time)
  #   assert_equal(14, methods[1].wait_time)
  #   assert_equal(2, methods[1].self_time)
  #   assert_equal(0, methods[1].children_time)
  #
  #   assert_equal('<Class::Thread>#new', methods[2].full_name)
  #   assert_equal(12, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(0, methods[2].self_time)
  #   assert_equal(0, methods[2].children_time)
  #
  #   assert_equal('Thread#initialize', methods[3].full_name)
  #   assert_equal(0, methods[3].total_time)
  #   assert_equal(0, methods[3].wait_time)
  #   assert_equal(0, methods[3].self_time)
  #   assert_equal(0, methods[3].children_time)
  #
  #   thread = result.threads.last
  #   assert_equal(0.2, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_instance_methods_threaded", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(4, methods.length)
  #
  #   methods = result.threads.last.methods.sort.reverse
  #   assert_equal(5, methods.length)
  #
  #   # Check times
  #   assert_equal('MeasureMemoryTest#test_instance_methods_threaded', methods[0].full_name)
  #   assert_equal(0.2, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(0, methods[0].self_time)
  #   assert_equal(0.2, methods[0].children_time)
  #
  #   assert_equal('RubyProf::C1#sleep_wait', methods[1].full_name)
  #   assert_equal(0.2, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(0, methods[1].self_time)
  #   assert_equal(0.2, methods[1].children_time)
  #
  #   assert_equal('Kernel#sleep', methods[2].full_name)
  #   assert_equal(0.2, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(0.2, methods[2].self_time)
  #   assert_equal(0, methods[2].children_time)
  #
  #   assert_equal('Class#new', methods[3].full_name)
  #   assert_equal(0, methods[3].total_time)
  #   assert_equal(0, methods[3].wait_time)
  #   assert_equal(0, methods[3].self_time)
  #   assert_equal(0, methods[3].children_time)
  #
  #   assert_equal('BasicObject#initialize', methods[4].full_name)
  #   assert_equal(0, methods[4].total_time)
  #   assert_equal(0, methods[4].wait_time)
  #   assert_equal(0, methods[4].self_time)
  #   assert_equal(0, methods[4].children_time)
  # end
  #
  # def test_module_methods
  #   result = RubyProf.profile do
  #     RubyProf::C2.sleep_wait
  #   end
  #
  #   thread = result.threads.first
  #   assert_equal(7, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_module_methods", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(3, methods.length)
  #
  #   assert_equal('MeasureMemoryTest#test_module_methods', methods[0].full_name)
  #   assert_equal('RubyProf::M1#sleep_wait', methods[1].full_name)
  #   assert_equal('Kernel#sleep', methods[2].full_name)
  #
  #   # Check times
  #   assert_equal(7, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(3, methods[0].self_time)
  #
  #   assert_equal(4, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(2, methods[1].self_time)
  #
  #   assert_equal(2, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(2, methods[2].self_time)
  # end
  #
  # def test_module_instance_methods
  #   result = RubyProf.profile do
  #     RubyProf::C2.new.sleep_wait
  #   end
  #
  #   thread = result.threads.first
  #   assert_equal(12, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_module_instance_methods", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(5, methods.length)
  #   names = methods.map(&:full_name)
  #   assert_equal('MeasureMemoryTest#test_module_instance_methods', names[0])
  #   assert_equal('Class#new', names[1])
  #   assert_equal('RubyProf::M1#sleep_wait', names[2])
  #   assert_equal('Kernel#sleep', names[3])
  #
  #   # order can differ
  #   assert(names.include?("BasicObject#initialize"))
  #
  #   # Check times
  #   assert_equal(12, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(3, methods[0].self_time)
  #
  #   assert_equal(5, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(3, methods[1].self_time)
  #
  #   assert_equal(4, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(2, methods[2].self_time)
  #
  #   assert_equal(2, methods[3].total_time)
  #   assert_equal(0, methods[3].wait_time)
  #   assert_equal(2, methods[3].self_time)
  #
  #   assert_equal(2, methods[4].total_time)
  #   assert_equal(0, methods[4].wait_time)
  #   assert_equal(2, methods[4].self_time)
  # end
  #
  # def test_singleton_methods
  #   result = RubyProf.profile do
  #     RubyProf::C3.instance.sleep_wait
  #   end
  #
  #   thread = result.threads.first
  #   assert_equal(16, thread.total_time)
  #
  #   root_methods = thread.root_methods
  #   assert_equal(1, root_methods.count)
  #   assert_equal("MeasureMemoryTest#test_singleton_methods", root_methods[0].full_name)
  #
  #   methods = result.threads.first.methods.sort.reverse
  #   assert_equal(7, methods.length)
  #
  #   assert_equal('MeasureMemoryTest#test_singleton_methods', methods[0].full_name)
  #   assert_equal(15, methods[0].total_time)
  #   assert_equal(0, methods[0].wait_time)
  #   assert_equal(2, methods[0].self_time)
  #   assert_equal(13, methods[0].children_time)
  #
  #   assert_equal('<Class::RubyProf::C3>#instance', methods[1].full_name)
  #   assert_equal(9, methods[1].total_time)
  #   assert_equal(0, methods[1].wait_time)
  #   assert_equal(3, methods[1].self_time)
  #   assert_equal(2, methods[1].children_time)
  #
  #   assert_equal('Thread::Mutex#synchronize', methods[2].full_name)
  #   assert_equal(0, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(0, methods[2].self_time)
  #   assert_equal(0, methods[2].children_time)
  #
  #   assert_equal('RubyProf::C3#sleep_wait', methods[3].full_name)
  #   assert_equal(0.3, methods[3].total_time)
  #   assert_equal(0, methods[3].wait_time)
  #   assert_equal(0, methods[3].self_time)
  #   assert_equal(0.3, methods[3].children_time)
  #
  #   assert_equal('Kernel#sleep', methods[3].full_name)
  #   assert_equal(0.3, methods[2].total_time)
  #   assert_equal(0, methods[2].wait_time)
  #   assert_equal(0.3, methods[2].self_time)
  #   assert_equal(0, methods[2].children_time)
  #
  #   assert_equal('Class#new', methods[5].full_name)
  #   assert_equal(0, methods[5].total_time)
  #   assert_equal(0, methods[5].wait_time)
  #   assert_equal(0, methods[5].self_time)
  #   assert_equal(0, methods[5].children_time)
  #
  #   assert_equal('BasicObject#initialize', methods[6].full_name)
  #   assert_equal(0, methods[6].total_time)
  #   assert_equal(0, methods[6].wait_time)
  #   assert_equal(0, methods[6].self_time)
  #   assert_equal(0, methods[6].children_time)
  # end
end
