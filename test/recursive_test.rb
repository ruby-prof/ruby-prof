#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'

def simple(n)
  sleep(1)
  n -= 1
  return if n == 0
  simple(n)
end

def cycle(n)
  sub_cycle(n)
end

def sub_cycle(n)
  sleep(1)
  n -= 1
  return if n == 0
  cycle(n)
end


# --  Tests ----
class RecursiveTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_simple
    result = RubyProf.profile do
      simple(2)
    end

    methods = result.threads.values.first.sort.reverse
    assert_equal(6, methods.length)

    method = methods[0]
    assert_equal('RecursiveTest#test_simple', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(2, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_simple', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[1]
    assert_equal('Object#simple', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(2, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_simple->Object#simple', call_info.call_sequence)
    assert_equal(4, call_info.children.length)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(2, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(2, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_simple->Object#simple->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('RecursiveTest#test_simple->Object#simple->Object#simple-1->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    method = methods[3]
    assert_equal('Object#simple-1', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(1, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_simple->Object#simple->Object#simple-1', call_info.call_sequence)
    assert_equal(3, call_info.children.length)

    method = methods[4]
    assert_equal('Fixnum#-', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(2, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_simple->Object#simple->Fixnum#-', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('RecursiveTest#test_simple->Object#simple->Object#simple-1->Fixnum#-', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    method = methods[5]
    assert_equal('Fixnum#==', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(2, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_simple->Object#simple->Fixnum#==', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('RecursiveTest#test_simple->Object#simple->Object#simple-1->Fixnum#==', call_info.call_sequence)
    assert_equal(0, call_info.children.length)
  end
  
  def test_cycle
    result = RubyProf.profile do
      cycle(2)
    end

    methods = result.threads.values.first.sort.reverse
    assert_equal(8, methods.length)

    method = methods[0]
    assert_equal('RecursiveTest#test_cycle', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(2, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[1]
    assert_equal('Object#cycle', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(2, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[2]
    assert_equal('Object#sub_cycle', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(2, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle', call_info.call_sequence)
    assert_equal(4, call_info.children.length)

    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(2, method.total_time, 0.01)
    assert_in_delta(2, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(2, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Object#cycle-1->Object#sub_cycle-1->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    method = methods[4]
    assert_equal('Object#cycle-1', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(1, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Object#cycle-1', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[5]
    assert_equal('Object#sub_cycle-1', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(1, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Object#cycle-1->Object#sub_cycle-1', call_info.call_sequence)
    assert_equal(3, call_info.children.length)

    method = methods[6]
    assert_equal('Fixnum#-', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(2, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Fixnum#-', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Object#cycle-1->Object#sub_cycle-1->Fixnum#-', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    method = methods[7]
    assert_equal('Fixnum#==', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(2, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Fixnum#==', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    call_info = method.call_infos[1]
    assert_equal('RecursiveTest#test_cycle->Object#cycle->Object#sub_cycle->Object#cycle-1->Object#sub_cycle-1->Fixnum#==', call_info.call_sequence)
    assert_equal(0, call_info.children.length)
  end
end