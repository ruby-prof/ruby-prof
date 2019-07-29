#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_allocations'

class MeasureAllocationsTraceTest < TestCase
  def setup
    RubyProf::measure_mode = RubyProf::ALLOCATIONS
  end

  def test_allocations_mode
    RubyProf::measure_mode = RubyProf::ALLOCATIONS
    assert_equal(RubyProf::ALLOCATIONS, RubyProf::measure_mode)
  end

  def test_allocations
    result = RubyProf.profile(:track_allocations => true) do
      allocator = Allocator.new
      allocator.run
    end

    thread = result.threads.first
    assert_in_delta(20, thread.total_time, 1)

    root_methods = thread.root_methods
    assert_equal(1, root_methods.count)
    assert_equal("MeasureAllocationsTraceTest#test_allocations", root_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(13, methods.length)

    # Method 0
    method = methods[0]
    assert_equal('MeasureAllocationsTraceTest#test_allocations',  method.full_name)
    assert_in_delta(20, method.total_time, 1)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_in_delta(20, method.children_time, 1)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_nil(call_info.parent)
    assert_equal(20, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(20, call_info.children_time)

    assert_equal(2, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(1, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Allocator#run', call_info.target.full_name)
    assert_equal(19, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(19, call_info.children_time)

    # Method 1
    method = methods[1]
    assert_equal('Allocator#run',method.full_name)
    assert_equal(19, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(19, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('MeasureAllocationsTraceTest#test_allocations', call_info.parent.full_name)
    assert_equal(19, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(19, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Allocator#internal_run', call_info.target.full_name)
    assert_equal(19, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(19, call_info.children_time)

    # Method 2
    method = methods[2]
    assert_equal('Allocator#internal_run',  method.full_name)
    assert_equal(19, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(19, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#run', call_info.parent.full_name)
    assert_equal(19, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(19, call_info.children_time)

    assert_equal(3, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Allocator#make_arrays', call_info.target.full_name)
    assert_equal(10, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(10, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Allocator#make_hashes', call_info.target.full_name)
    assert_equal(5, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(5, call_info.children_time)

    call_info = method.callees[2]
    assert_equal('Allocator#make_strings', call_info.target.full_name)
    assert_equal(4, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(3, call_info.children_time)

    # Method 3
    method = methods[3]
    assert_equal('Class#new', method.full_name)
    assert_equal(18, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(17, method.self_time)
    assert_equal(1, method.children_time)

    assert_equal(4, method.callers.length)
    call_info = method.callers[0]
    assert_equal('MeasureAllocationsTraceTest#test_allocations', call_info.parent.full_name)
    assert_equal(1, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callers[1]
    assert_equal('Integer#times', call_info.parent.full_name)
    assert_equal(10, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(10, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callers[2]
    assert_equal('Allocator#make_hashes', call_info.parent.full_name)
    assert_equal(5, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(5, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callers[3]
    assert_equal('Allocator#make_strings', call_info.parent.full_name)
    assert_equal(2, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(1, call_info.children_time)

    assert_equal(4, method.callees.length)
    call_info = method.callees[0]
    assert_equal('BasicObject#initialize', call_info.target.full_name)
    assert_equal(0, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Array#initialize', call_info.target.full_name)
    assert_equal(0, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callees[2]
    assert_equal('Hash#initialize', call_info.target.full_name)
    assert_equal(0, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callees[3]
    assert_equal('String#initialize', call_info.target.full_name)
    assert_equal(1, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(0, call_info.children_time)

    # Method 4
    method = methods[4]
    assert_equal('Allocator#make_arrays', method.full_name)
    assert_equal(10, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(10, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#internal_run', call_info.parent.full_name)
    assert_equal(10, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(10, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Integer#times', call_info.target.full_name)
    assert_equal(10, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(10, call_info.children_time)

    # Method 5
    method = methods[5]
    assert_equal('Integer#times', method.full_name)
    assert_equal(10, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(10, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#make_arrays', call_info.parent.full_name)
    assert_equal(10, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(10, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(10, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(10, call_info.self_time)
    assert_equal(0, call_info.children_time)

    # Method 6
    method = methods[6]
    assert_equal('Allocator#make_hashes', method.full_name)
    assert_equal(5, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(5, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#internal_run', call_info.parent.full_name)
    assert_equal(5, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(5, call_info.children_time)

    assert_equal(1, method.callees.length)
    call_info = method.callees[0]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(5, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(5, call_info.self_time)
    assert_equal(0, call_info.children_time)

    # Method 7
    method = methods[7]
    assert_equal('Allocator#make_strings', method.full_name)
    assert_equal(4, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(1, method.self_time)
    assert_equal(3, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#internal_run', call_info.parent.full_name)
    assert_equal(4, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(3, call_info.children_time)

    assert_equal(2, method.callees.length)
    call_info = method.callees[0]
    assert_equal('String#*', call_info.target.full_name)
    assert_equal(1, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(0, call_info.children_time)

    call_info = method.callees[1]
    assert_equal('Class#new', call_info.target.full_name)
    assert_equal(2, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(1, call_info.children_time)

    # Method 8
    method = methods[8]
    assert_equal('String#*', method.full_name)
    assert_equal(1, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(1, method.self_time)
    assert_equal(0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Allocator#make_strings', call_info.parent.full_name)
    assert_equal(1, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(0, call_info.children_time)

    assert_equal(0, method.callees.length)

    # Method 9
    method = methods[9]
    assert_equal('String#initialize', method.full_name)
    assert_equal(1, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(1, method.self_time)
    assert_equal(0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(1, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(1, call_info.self_time)
    assert_equal(0, call_info.children_time)

    assert_equal(0, method.callees.length)

    # Method 10
    method = methods[10]
    assert_equal('BasicObject#initialize', method.full_name)
    assert_equal(0, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(0, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(0, call_info.children_time)

    assert_equal(0, method.callees.length)

    # Method 11
    method = methods[11]
    assert_equal('Hash#initialize', method.full_name)
    assert_equal(0, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(0, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(0, call_info.children_time)

    assert_equal(0, method.callees.length)

    # Method 12
    method = methods[12]
    assert_equal('Array#initialize', method.full_name)
    assert_equal(0, method.total_time)
    assert_equal(0, method.wait_time)
    assert_equal(0, method.self_time)
    assert_equal(0, method.children_time)

    assert_equal(1, method.callers.length)
    call_info = method.callers[0]
    assert_equal('Class#new', call_info.parent.full_name)
    assert_equal(0, call_info.total_time)
    assert_equal(0, call_info.wait_time)
    assert_equal(0, call_info.self_time)
    assert_equal(0, call_info.children_time)

    assert_equal(0, method.callees.length)
  end
end
