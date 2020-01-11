#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

module SimpleRecursion
  # Simple recursive test
  def simple(n)
    sleep(1)
    return if n == 0
    simple(n-1)
  end

  # More complicated recursive test
  def render_partial(i)
    sleep(1)
    case i
    when 0
      render_partial(10)
    when 1
      2.times do |j|
        render_partial(j + 10)
      end
    end
  end

  def render
    2.times do |i|
      render_partial(i)
    end
  end
end

# --  Tests ----
class RecursiveTest < TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  include SimpleRecursion

  def test_simple
    result = RubyProf.profile do
      simple(1)
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Method 0: RecursiveTest#test_simple
    method = methods[0]
    assert_equal('RecursiveTest#test_simple', method.full_name)
    assert_equal(1, method.called)
    refute(method.recursive?)
    assert_in_delta(2, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(2, method.children_time, 0.1)

    assert_equal(0, method.call_infos.callers.length)

    assert_equal(1, method.call_infos.callees.length)
    call_info = method.call_infos.callees[0]
    assert_equal('SimpleRecursion#simple', call_info.target.full_name)

    # Method 1: SimpleRecursion#simple
    method = methods[1]
    assert_equal('SimpleRecursion#simple', method.full_name)
    assert_equal(2, method.called)
    assert(method.recursive?)
    assert_in_delta(2, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.1)
    assert_in_delta(0, method.wait_time, 0.1)
    assert_in_delta(2, method.children_time, 0.1)

    assert_equal(2, method.call_infos.callers.length)
    call_info = method.call_infos.callers[0]
    assert_equal('RecursiveTest#test_simple', call_info.parent.target.full_name)

    call_info = method.call_infos.callers[1]
    assert_equal('SimpleRecursion#simple', call_info.parent.target.full_name)

    assert_equal(2, method.call_infos.callees.length)
    call_info = method.call_infos.callees[0]
    assert_equal('Kernel#sleep', call_info.target.full_name)

    call_info = method.call_infos.callees[1]
    assert_equal('SimpleRecursion#simple', call_info.target.full_name)

    # Method 2: Kernel#sleep
    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.called)
    refute(method.recursive?)
    assert_in_delta(2, method.total_time, 0.1)
    assert_in_delta(2, method.self_time, 0.1)
    assert_in_delta(0, method.wait_time, 0.1)
    assert_in_delta(0, method.children_time, 0.1)

    assert_equal(1, method.call_infos.callers.length)
    call_info = method.call_infos.callers[0]
    assert_equal('SimpleRecursion#simple', call_info.parent.target.full_name)
    assert_equal(0, method.call_infos.callees.length)

    assert_equal(0, method.call_infos.callees.length)
  end

  def test_cycle
    result = RubyProf.profile do
      render
    end

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)

    method = methods[0]
    assert_equal('RecursiveTest#test_cycle', method.full_name)
    assert_equal(1, method.called)
    refute(method.recursive?)
    assert_in_delta(5, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(5, method.children_time, 0.1)

    assert_equal(0, method.call_infos.callers.length)

    assert_equal(1, method.call_infos.callees.length)
    call_info = method.call_infos.callees[0]
    assert_equal('SimpleRecursion#render', call_info.target.full_name)

    method = methods[1]
    assert_equal('SimpleRecursion#render', method.full_name)
    assert_equal(1, method.called)
    refute(method.recursive?)
    assert_in_delta(5, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(5, method.children_time, 0.1)

    assert_equal(1, method.call_infos.callers.length)
    call_info = method.call_infos.callers[0]
    assert_equal('RecursiveTest#test_cycle', call_info.parent.target.full_name)

    assert_equal(1, method.call_infos.callees.length)
    call_info = method.call_infos.callees[0]
    assert_equal('Integer#times', call_info.target.full_name)

    method = methods[2]
    assert_equal('Integer#times', method.full_name)
    assert_equal(2, method.called)
    assert(method.recursive?)
    assert_in_delta(5, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.1)
    assert_in_delta(0, method.wait_time, 0.1)
    assert_in_delta(5, method.children_time, 0.1)

    assert_equal(2, method.call_infos.callers.length)
    call_info = method.call_infos.callers[0]
    assert_equal('SimpleRecursion#render', call_info.parent.target.full_name)

    call_info = method.call_infos.callers[1]
    assert_equal('SimpleRecursion#render_partial', call_info.parent.target.full_name)

    assert_equal(1, method.call_infos.callees.length)
    call_info = method.call_infos.callees[0]
    assert_equal('SimpleRecursion#render_partial', call_info.target.full_name)

    method = methods[3]
    assert_equal('SimpleRecursion#render_partial', method.full_name)
    assert_equal(5, method.called)
    assert(method.recursive?)
    assert_in_delta(5, method.total_time, 0.1)
    assert_in_delta(0, method.self_time, 0.1)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(5, method.children_time, 0.05)

    assert_equal(2, method.call_infos.callers.length)
    call_info = method.call_infos.callers[0]
    assert_equal('Integer#times', call_info.parent.target.full_name)

    call_info = method.call_infos.callers[1]
    assert_equal('SimpleRecursion#render_partial', call_info.parent.target.full_name)

    assert_equal(3, method.call_infos.callees.length)
    call_info = method.call_infos.callees[0]
    assert_equal('Kernel#sleep', call_info.target.full_name)

    call_info = method.call_infos.callees[1]
    assert_equal('SimpleRecursion#render_partial', call_info.target.full_name)

    call_info = method.call_infos.callees[2]
    assert_equal('Integer#times', call_info.target.full_name)

    method = methods[4]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(5, method.called)
    refute(method.recursive?)
    assert_in_delta(5, method.total_time, 0.1)
    assert_in_delta(5, method.self_time, 0.1)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(0, method.call_infos.callees.length)
  end
end
