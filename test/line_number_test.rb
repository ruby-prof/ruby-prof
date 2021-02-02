#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class LineNumbers
  def method_1
    method_2
    _filler = 1
    method_3
  end

  def method_2
    _filler = 1
    2.times do |i|
      _filler = 2
      method_3
    end
  end

  def method_3
    sleep(0.3)
    method_4
  end

  def method_4
    sleep(1.2)
  end
end

# --  Tests ----
class LineNumbersTest < TestCase
  def test_function_line_no
    numbers = LineNumbers.new

    result = RubyProf.profile do
      numbers.method_1
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(7, methods.length)

    # Method 0
    method = methods[0]
    assert_equal('LineNumbersTest#test_function_line_no', method.full_name)
    assert_equal(37, method.line)

    assert_equal(0, method.call_trees.callers.count)

    assert_equal(1, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('LineNumbers#method_1', call_tree.target.full_name)
    assert_equal(37, call_tree.line)

    # Method 1
    method = methods[1]
    assert_equal('LineNumbers#method_1', method.full_name)
    assert_equal(7, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('LineNumbersTest#test_function_line_no', call_tree.parent.target.full_name)
    assert_equal(37, call_tree.line)

    assert_equal(2, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('LineNumbers#method_2', call_tree.target.full_name)
    assert_equal(8, call_tree.line)

    call_tree = method.call_trees.callees[1]
    assert_equal('LineNumbers#method_3', call_tree.target.full_name)
    assert_equal(10, call_tree.line)

    # Method 2
    method = methods[2]
    assert_equal('LineNumbers#method_3', method.full_name)
    assert_equal(21, method.line)

    assert_equal(2, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('Integer#times', call_tree.parent.target.full_name)
    assert_equal(17, call_tree.line)

    call_tree = method.call_trees.callers[1]
    assert_equal('LineNumbers#method_1', call_tree.parent.target.full_name)
    assert_equal(10, call_tree.line)

    assert_equal(2, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(22, call_tree.line)

    call_tree = method.call_trees.callees[1]
    assert_equal('LineNumbers#method_4', call_tree.target.full_name)
    assert_equal(23, call_tree.line)

    # Method 3
    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(0, method.line)

    assert_equal(2, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('LineNumbers#method_3', call_tree.parent.target.full_name)
    assert_equal(22, call_tree.line)

    call_tree = method.call_trees.callers[1]
    assert_equal('LineNumbers#method_4', call_tree.parent.target.full_name)
    assert_equal(27, call_tree.line)

    assert_equal(0, method.call_trees.callees.count)

    # Method 4
    method = methods[4]
    assert_equal('LineNumbers#method_4', method.full_name)
    assert_equal(26, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('LineNumbers#method_3', call_tree.parent.target.full_name)
    assert_equal(23, call_tree.line)

    assert_equal(1, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('Kernel#sleep', call_tree.target.full_name)
    assert_equal(27, call_tree.line)

    # Method 5
    method = methods[5]
    assert_equal('LineNumbers#method_2', method.full_name)
    assert_equal(13, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('LineNumbers#method_1', call_tree.parent.target.full_name)
    assert_equal(8, call_tree.line)

    assert_equal(1, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('Integer#times', call_tree.target.full_name)
    assert_equal(15, call_tree.line)

    # Method 6
    method = methods[6]
    assert_equal('Integer#times', method.full_name)
    assert_equal(0, method.line)

    assert_equal(1, method.call_trees.callers.count)
    call_tree = method.call_trees.callers[0]
    assert_equal('LineNumbers#method_2', call_tree.parent.target.full_name)
    assert_equal(15, call_tree.line)

    assert_equal(1, method.call_trees.callees.count)
    call_tree = method.call_trees.callees[0]
    assert_equal('LineNumbers#method_3', call_tree.target.full_name)
    assert_equal(17, call_tree.line)
  end
end
