#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_allocations'

class MeasureMemoryTraceTest < TestCase
  def setup
    RubyProf::measure_mode = RubyProf::MEMORY
  end

  def test_memory_mode
    RubyProf::measure_mode = RubyProf::MEMORY
    assert_equal(RubyProf::MEMORY, RubyProf::measure_mode)
  end

  def test_memory
    result = RubyProf.profile do
      allocator = Allocator.new
      allocator.run
    end

    thread = result.threads.first
    assert_in_delta(1760, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureMemoryTraceTest#test_memory", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(13, methods.length)

    # Method 0
    method = methods[0]
    assert_equal('MeasureMemoryTraceTest#test_memory',  method.full_name)
    assert_in_delta(1760, method.total_time, 1)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_in_delta(1760, method.children_time, 1)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_nil(call_info.parent)
    assert_equal(1760, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1760, call_info.children_time)

    assert_equal(2, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(40.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Allocator#run', call_info.target.full_name)
    assert_equal(1720.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1720.0, call_info.children_time)

    # Method 1
    method = methods[1]
    assert_equal('Allocator#run',method.full_name)
    assert_equal(1720.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(1720.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('MeasureMemoryTraceTest#test_memory', call_info.parent.full_name)
    assert_equal(1720.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1720.0, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Allocator#internal_run', call_info.target.full_name)
    assert_equal(1720.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1720.0, call_info.children_time)

    # Method 2
    method = methods[2]
    assert_equal('Allocator#internal_run',  method.full_name)
    assert_equal(1720.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(1720.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#run', call_info.parent.full_name)
    assert_equal(1720.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1720.0, call_info.children_time)

    assert_equal(3, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Allocator#make_arrays', call_info.target.full_name)
    assert_equal(400.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(400.0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Allocator#make_hashes', call_info.target.full_name)
    assert_equal(1160.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1160.0, call_info.children_time)

    call_info = method.callees[2]
    assert_equal('Allocator#make_strings', call_info.target.full_name)
    assert_equal(160.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40, call_info.self_time)
    assert_equal(120.0, call_info.children_time)

    # Method 3
    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_equal(1680.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(1640.0, method.self_time)
    assert_equal(40.0, method.children_time)

    assert_equal(4, method.callers.length)
    call_info = method.callers[0]
    assert_equal('MeasureMemoryTraceTest#test_memory', call_info.parent.full_name)
    assert_equal(40.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callers[1]
    assert_equal('Integer#times', call_info.parent.full_name)
    assert_equal(400.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(400.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callers[2]
    assert_equal('Allocator#make_hashes', call_info.parent.full_name)
    assert_equal(1160.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(1160.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callers[3]
    assert_equal('Allocator#make_strings', call_info.parent.full_name)
    assert_equal(80.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(40.0, call_info.children_time)

    assert_equal(4, method.callees.length)
    call_info = method.callees[0]
    assert_equal('BasicObject#initialize', call_info.target.full_name)
    assert_equal(0.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Array#initialize', call_info.target.full_name)
    assert_equal(0.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callees[2]
    assert_equal('Hash#initialize', call_info.target.full_name)
    assert_equal(0.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callees[3]
    assert_equal('String#initialize', call_info.target.full_name)
    assert_equal(40.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    # Method 4
    method = methods[4]
    assert_equal('Allocator#make_hashes', method.full_name)
    assert_equal(1160.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(1160.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#internal_run', call_info.parent.full_name)
    assert_equal(1160.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(1160.0, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(1160.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(1160.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    # Method 5
    method = methods[5]
    assert_equal('Allocator#make_arrays', method.full_name)
    assert_equal(400.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(400.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#internal_run', call_info.parent.full_name)
    assert_equal(400.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(400.0, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Integer#times', call_info.target.full_name)
    assert_equal(400.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(400.0, call_info.children_time)

    # Method 6
    method = methods[6]
    assert_equal('Integer#times', method.full_name)
    assert_equal(400.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(400.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#make_arrays', call_info.parent.full_name)
    assert_equal(400.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(400.0, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(400.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(400.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    # Method 7
    method = methods[7]
    assert_equal('Allocator#make_strings', method.full_name)
    assert_equal(160.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(40.0, method.self_time)
    assert_equal(120.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#internal_run', call_info.parent.full_name)
    assert_equal(160.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(120.0, call_info.children_time)

    assert_equal(2, method.callees.length)
    call_info = method.callees[0]
    assert_equal('String#*', call_info.target.full_name)
    assert_equal(40.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(80.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(40.0, call_info.children_time)

    # Method 8
    method = methods[8]
    assert_equal('String#*', method.full_name)
    assert_equal(40.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(40.0, method.self_time)
    assert_equal(0.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#make_strings', call_info.parent.full_name)
    assert_equal(40.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    assert_equal(0.0, method.callees.length)

    # Method 9
    method = methods[9]
    assert_equal('String#initialize', method.full_name)
    assert_equal(40.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(40.0, method.self_time)
    assert_equal(0.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(40.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(40.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    assert_equal(0.0, method.callees.length)

    # Method 10
    method = methods[10]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_equal(0.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(0.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(0.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    assert_equal(0.0, method.callees.length)

    # Method 11
    method = methods[11]
    assert_equal('Hash#initialize', method.full_name)
    assert_equal(0.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(0.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(0.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    assert_equal(0.0, method.callees.length)

    # Method 12
    method = methods[12]
    assert_equal('Array#initialize', method.full_name)
    assert_equal(0.0, method.total_time)
    assert_equal(0.0, method.wait_time)
    assert_equal(0.0, method.self_time)
    assert_equal(0.0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(0.0, call_info.total_time)
    assert_equal(0.0, call_info.wait_time)
    assert_equal(0.0, call_info.self_time)
    assert_equal(0.0, call_info.children_time)

    assert_equal(0.0, method.callees.length)
  end
end
