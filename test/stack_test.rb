#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'

# Test data
#     A
#    / \
#   B   C
#        \
#         B

class C1
  def a
    sleep 1
    b
    c
  end

  def b
    sleep 2
  end

  def c
    sleep 3
    b
  end
end

class StackTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_call_sequence
    c = C1.new
    result = RubyProf.profile do
      c.a
    end

    # Length should be 5:
    #   StackTest#test_call_sequence
    #   C1#a
    #   Kernel#sleep
    #   C1#c
    #   C1#b

    methods = result.threads.values.first.sort.reverse
    assert_equal(5, methods.length)

    # Check StackTest#test_call_sequence
    method = methods[0]
    assert_equal('StackTest#test_call_sequence', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(8, method.total_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(8, method.children_time, 0.01)
    assert_equal(1, method.call_infos.length)

    call_info = method.call_infos[0]
    assert_equal('StackTest#test_call_sequence', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    # Check C1#a
    method = methods[1]
    assert_equal('C1#a', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(8, method.total_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(8, method.children_time, 0.01)
    assert_equal(1, method.call_infos.length)

    call_info = method.call_infos[0]
    assert_equal('StackTest#test_call_sequence->C1#a', call_info.call_sequence)
    assert_equal(3, call_info.children.length)
    
    # Check Kernel#sleep
    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(4, method.called)
    assert_in_delta(8, method.total_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(8, method.self_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)
    assert_equal(4, method.call_infos.length)

    call_info = method.call_infos[0]
    assert_equal('StackTest#test_call_sequence->C1#a->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('StackTest#test_call_sequence->C1#a->C1#b->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[2]
    assert_equal('StackTest#test_call_sequence->C1#a->C1#c->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[3]
    assert_equal('StackTest#test_call_sequence->C1#a->C1#c->C1#b->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    # Check C1#c
    method = methods[3]
    assert_equal('C1#c', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(5, method.total_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(5, method.children_time, 0.01)
    assert_equal(1, method.call_infos.length)

    call_info = method.call_infos[0]
    assert_equal('StackTest#test_call_sequence->C1#a->C1#c', call_info.call_sequence)
    assert_equal(2, call_info.children.length)

    # Check C1#b
    method = methods[4]
    assert_equal('C1#b', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(4, method.total_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(4, method.children_time, 0.01)
    assert_equal(2, method.call_infos.length)

    call_info = method.call_infos[0]
    assert_equal('StackTest#test_call_sequence->C1#a->C1#b', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('StackTest#test_call_sequence->C1#a->C1#c->C1#b', call_info.call_sequence)
    assert_equal(1, call_info.children.length)
  end
end