#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# --  Tests ----
class CallInfosTest < TestCase
  def some_method_1
    some_method_2
  end

  def some_method_2
  end

  def test_call_infos
    result = RubyProf.profile do
      some_method_1
    end

    thread = result.threads.first
    assert_equal(3, thread.methods.length)

    method = thread.methods[0]
    assert_equal('CallInfosTest#test_call_infos', method.full_name)

    call_infos = method.call_infos
    assert_empty(call_infos.callers)
    assert_equal(1, call_infos.callees.length)
    assert_kind_of(RubyProf::AggregateCallInfo, call_infos.callees[0])
    assert_equal('CallInfosTest#some_method_1', call_infos.callees[0].target.full_name)

    method = thread.methods[1]
    assert_equal('CallInfosTest#some_method_1', method.full_name)

    call_infos = method.call_infos
    assert_equal(1, call_infos.callers.length)
    assert_kind_of(RubyProf::AggregateCallInfo, call_infos.callers[0])
    assert_equal('CallInfosTest#test_call_infos', call_infos.callers[0].parent.target.full_name)
    assert_equal(1, call_infos.callees.length)
    assert_kind_of(RubyProf::AggregateCallInfo, call_infos.callees[0])
    assert_equal('CallInfosTest#some_method_2', call_infos.callees[0].target.full_name)

    method = thread.methods[2]
    assert_equal('CallInfosTest#some_method_2', method.full_name)

    call_infos = method.call_infos
    assert_equal(1, call_infos.callers.length)
    assert_kind_of(RubyProf::AggregateCallInfo, call_infos.callers[0])
    assert_equal('CallInfosTest#some_method_1', call_infos.callers[0].parent.target.full_name)
    assert_empty(call_infos.callees)
  end

  def test_gc
    result = RubyProf.profile do
      some_method_1
    end

    method = result.threads.first.methods[1]

    100.times do |i|
      aggregated_call_infos = method.call_infos.callers
      GC.start
    end
    assert(true)
  end
end
