#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require_relative './measure_allocations'

class MeasureAllocationsTest < TestCase
  def test_allocations
    result = RubyProf::Profile.profile(measure_mode: RubyProf::ALLOCATIONS, track_allocations: true) do
      allocator = Allocator.new
      allocator.run
    end

    thread = result.threads.first
    assert_in_delta(20, thread.total_time, 1)

    methods = result.threads.first.methods.sort.reverse

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
      assert_equal(13, methods.length)

      # Method 0
      method = methods[0]
      assert_equal('MeasureAllocationsTest#test_allocations',  method.full_name)
      assert_in_delta(20, method.total_time, 1)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_in_delta(20, method.children_time, 1)

      assert_equal(0, method.call_trees.callers.length)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Allocator#run', call_tree.target.full_name)
      assert_equal(19, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(19, call_tree.children_time)

      # Method 1
      method = methods[1]
      assert_equal('Allocator#run',method.full_name)
      assert_equal(19, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(19, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('MeasureAllocationsTest#test_allocations', call_tree.parent.target.full_name)
      assert_equal(19, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(19, call_tree.children_time)

      assert_equal(3, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Allocator#make_arrays', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Allocator#make_hashes', call_tree.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(5, call_tree.children_time)

      call_tree = method.call_trees.callees[2]
      assert_equal('Allocator#make_strings', call_tree.target.full_name)
      assert_equal(4, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(3, call_tree.children_time)

      # Method 2
      method = methods[2]
      assert_equal('Allocator#make_arrays', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(10, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Integer#times', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      # Method 3
      method = methods[3]
      assert_equal('Integer#times', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(10, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_arrays', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('<Class::Array>#new', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(10, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 4
      method = methods[4]
      assert_equal('<Class::Array>#new', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(10, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(10, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Array#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 5
      method = methods[5]
      assert_equal('Class#new', method.full_name)
      assert_equal(8, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(7, method.self_time)
      assert_equal(1, method.children_time)

      assert_equal(3, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('MeasureAllocationsTest#test_allocations', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callers[1]
      assert_equal('Allocator#make_hashes', call_tree.parent.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(5, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callers[2]
      assert_equal('Allocator#make_strings', call_tree.parent.target.full_name)
      assert_equal(2, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(1, call_tree.children_time)

      assert_equal(3, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('BasicObject#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Hash#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[2]
      assert_equal('String#initialize', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 6
      method = methods[6]
      assert_equal('Allocator#make_hashes', method.full_name)
      assert_equal(5, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(5, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(5, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(5, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 7
      method = methods[7]
      assert_equal('Allocator#make_strings', method.full_name)
      assert_equal(4, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(3, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(4, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(3, call_tree.children_time)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('String#*', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(2, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(1, call_tree.children_time)

      # Method 8
      method = methods[8]
      assert_equal('String#*', method.full_name)
      assert_equal(1, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_strings', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 9
      method = methods[9]
      assert_equal('String#initialize', method.full_name)
      assert_equal(1, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 10
      method = methods[10]
      assert_equal('BasicObject#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 11
      method = methods[11]
      assert_equal('Hash#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 12
      method = methods[12]
      assert_equal('Array#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('<Class::Array>#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)
    elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.4')
      assert_equal(17, methods.length)

      # Method 0
      method = methods[0]
      assert_equal('MeasureAllocationsTest#test_allocations',  method.full_name)
      assert_in_delta(20, method.total_time, 1)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_in_delta(20, method.children_time, 1)

      assert_equal(0, method.call_trees.callers.length)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Allocator#run', call_tree.target.full_name)
      assert_equal(19, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(19, call_tree.children_time)

      # Method 1
      method = methods[1]
      assert_equal('Allocator#run',method.full_name)
      assert_equal(19, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(19, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('MeasureAllocationsTest#test_allocations', call_tree.parent.target.full_name)
      assert_equal(19, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(19, call_tree.children_time)

      assert_equal(3, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Allocator#make_arrays', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Allocator#make_hashes', call_tree.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(5, call_tree.children_time)

      call_tree = method.call_trees.callees[2]
      assert_equal('Allocator#make_strings', call_tree.target.full_name)
      assert_equal(4, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(3, call_tree.children_time)

      # Method 2
      method = methods[2]
      assert_equal('Allocator#make_arrays', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(10, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Integer#times', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      # Method 3
      method = methods[3]
      assert_equal('Integer#times', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(10, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_arrays', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      assert_equal(4, method.call_trees.callees.length)

      call_tree = method.call_trees.callees[0]
      assert_equal('Kernel#block_given?', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Integer#<', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[2]
      assert_equal('<Class::Array>#new', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(10, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[3]
      assert_equal('Integer#succ', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 4
      method = methods[4]
      assert_equal('<Class::Array>#new', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(10, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(10, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Array#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 5
      method = methods[5]
      assert_equal('Class#new', method.full_name)
      assert_equal(6, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(6, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(2, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('MeasureAllocationsTest#test_allocations', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callers[1]
      assert_equal('Allocator#make_hashes', call_tree.parent.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(5, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('BasicObject#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Hash#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 6
      method = methods[6]
      assert_equal('Allocator#make_hashes', method.full_name)
      assert_equal(5, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(5, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(5, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(5, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 7
      method = methods[7]
      assert_equal('Allocator#make_strings', method.full_name)
      assert_equal(4, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(3, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(4, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(3, call_tree.children_time)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('String#*', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('<Class::String>#new', call_tree.target.full_name)
      assert_equal(2, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(1, call_tree.children_time)

      # Method 8
      method = methods[8]
      assert_equal('<Class::String>#new', method.full_name)
      assert_equal(2, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(1, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_strings', call_tree.parent.target.full_name)
      assert_equal(2, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(1, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)

      call_tree = method.call_trees.callees[0]
      assert_equal('String#initialize', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 9
      method = methods[9]
      assert_equal('String#*', method.full_name)
      assert_equal(1, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_strings', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 10
      method = methods[10]
      assert_equal('String#initialize', method.full_name)
      assert_equal(1, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('<Class::String>#new', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 11
      method = methods[11]
      assert_equal('BasicObject#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 12
      method = methods[12]
      assert_equal('Kernel#block_given?', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 13
      method = methods[13]
      assert_equal('Integer#succ', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 14
      method = methods[14]
      assert_equal('Integer#<', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 15
      method = methods[15]
      assert_equal('Hash#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 16
      method = methods[16]
      assert_equal('Array#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('<Class::Array>#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)
    else
      assert_equal(16, methods.length)

      # Method 0
      method = methods[0]
      assert_equal('MeasureAllocationsTest#test_allocations',  method.full_name)
      assert_in_delta(20, method.total_time, 1)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_in_delta(20, method.children_time, 1)

      assert_equal(0, method.call_trees.callers.length)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Allocator#run', call_tree.target.full_name)
      assert_equal(19, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(19, call_tree.children_time)

      # Method 1
      method = methods[1]
      assert_equal('Allocator#run',method.full_name)
      assert_equal(19, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(19, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('MeasureAllocationsTest#test_allocations', call_tree.parent.target.full_name)
      assert_equal(19, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(19, call_tree.children_time)

      assert_equal(3, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Allocator#make_arrays', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Allocator#make_hashes', call_tree.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(5, call_tree.children_time)

      call_tree = method.call_trees.callees[2]
      assert_equal('Allocator#make_strings', call_tree.target.full_name)
      assert_equal(4, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(3, call_tree.children_time)

      # Method 2
      method = methods[2]
      assert_equal('Allocator#make_arrays', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(10, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Integer#times', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      # Method 3
      method = methods[3]
      assert_equal('Integer#times', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(10, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_arrays', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(10, call_tree.children_time)

      assert_equal(3, method.call_trees.callees.length)

      call_tree = method.call_trees.callees[0]
      assert_equal('Integer#<', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('<Class::Array>#new', call_tree.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(10, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[2]
      assert_equal('Integer#succ', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 4
      method = methods[4]
      assert_equal('<Class::Array>#new', method.full_name)
      assert_equal(10, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(10, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(10, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(10, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Array#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 5
      method = methods[5]
      assert_equal('Class#new', method.full_name)
      assert_equal(6, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(6, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(2, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('MeasureAllocationsTest#test_allocations', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callers[1]
      assert_equal('Allocator#make_hashes', call_tree.parent.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(5, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('BasicObject#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('Hash#initialize', call_tree.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 6
      method = methods[6]
      assert_equal('Allocator#make_hashes', method.full_name)
      assert_equal(5, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(5, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(5, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('Class#new', call_tree.target.full_name)
      assert_equal(5, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(5, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 7
      method = methods[7]
      assert_equal('Allocator#make_strings', method.full_name)
      assert_equal(4, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(3, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#run', call_tree.parent.target.full_name)
      assert_equal(4, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(3, call_tree.children_time)

      assert_equal(2, method.call_trees.callees.length)
      call_tree = method.call_trees.callees[0]
      assert_equal('String#*', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      call_tree = method.call_trees.callees[1]
      assert_equal('<Class::String>#new', call_tree.target.full_name)
      assert_equal(2, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(1, call_tree.children_time)

      # Method 8
      method = methods[8]
      assert_equal('<Class::String>#new', method.full_name)
      assert_equal(2, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(1, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_strings', call_tree.parent.target.full_name)
      assert_equal(2, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(1, call_tree.children_time)

      assert_equal(1, method.call_trees.callees.length)

      call_tree = method.call_trees.callees[0]
      assert_equal('String#initialize', call_tree.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      # Method 9
      method = methods[9]
      assert_equal('String#*', method.full_name)
      assert_equal(1, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Allocator#make_strings', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 10
      method = methods[10]
      assert_equal('String#initialize', method.full_name)
      assert_equal(1, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(1, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('<Class::String>#new', call_tree.parent.target.full_name)
      assert_equal(1, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(1, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 11
      method = methods[11]
      assert_equal('BasicObject#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 12
      method = methods[12]
      assert_equal('Integer#succ', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 13
      method = methods[13]
      assert_equal('Integer#<', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Integer#times', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 14
      method = methods[14]
      assert_equal('Hash#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('Class#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)

      # Method 15
      method = methods[15]
      assert_equal('Array#initialize', method.full_name)
      assert_equal(0, method.total_time)
      assert_equal(0, method.wait_time)
      assert_equal(0, method.self_time)
      assert_equal(0, method.children_time)

      assert_equal(1, method.call_trees.callers.length)
      call_tree = method.call_trees.callers[0]
      assert_equal('<Class::Array>#new', call_tree.parent.target.full_name)
      assert_equal(0, call_tree.total_time)
      assert_equal(0, call_tree.wait_time)
      assert_equal(0, call_tree.self_time)
      assert_equal(0, call_tree.children_time)

      assert_equal(0, method.call_trees.callees.length)
    end
  end
end
