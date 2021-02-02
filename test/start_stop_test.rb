#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class StartStopTest < TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def method1
     RubyProf.start
     method2
  end

  def method2
     method3
  end

  def method3
    sleep(2)
    @result = RubyProf.stop
  end
  
  def test_extra_stop_should_raise
    RubyProf.start
    assert_raises(RuntimeError) do
      RubyProf.start
    end
    
    assert_raises(RuntimeError) do
      RubyProf.profile {}
    end
    
    RubyProf.stop # ok
    assert_raises(RuntimeError) do
      RubyProf.stop
    end
  end
    
  def test_different_methods
    method1

    # Ruby prof should be stopped
    assert_equal(false, RubyProf.running?)

    methods = @result.threads.first.methods.sort.reverse
    assert_equal(4, methods.length)

    method = methods[0]
    assert_equal('StartStopTest#method1', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.02)
    assert_in_delta(0, method.self_time, 0.02)
    assert_in_delta(2, method.children_time, 0.05)

    assert_equal(1, method.call_trees.callees.length)
    call_tree = method.call_trees.callees[0]
    assert_equal('StartStopTest#method2', call_tree.target.full_name)

    method = methods[1]
    assert_equal('StartStopTest#method2', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.02)
    assert_in_delta(0, method.self_time, 0.02)
    assert_in_delta(2, method.children_time, 0.05)

    assert_equal(1, method.call_trees.callers.length)
    call_tree = method.call_trees.callers[0]
    assert_equal('StartStopTest#method1', call_tree.parent.target.full_name)

    assert_equal(1, method.call_trees.callees.length)
    call_tree = method.call_trees.callees[0]
    assert_equal('StartStopTest#method3', call_tree.target.full_name)

    method = methods[2]
    assert_equal('StartStopTest#method3', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.02)
    assert_in_delta(0, method.wait_time, 0.02)
    assert_in_delta(0, method.self_time, 0.02)
    assert_in_delta(2, method.children_time, 0.02)

    assert_equal(1, method.call_trees.callers.length)
    call_tree = method.call_trees.callers[0]
    assert_equal('StartStopTest#method2', call_tree.parent.target.full_name)

    assert_equal(1, method.call_trees.callees.length)
    call_tree = method.call_trees.callees[0]
    assert_equal('Kernel#sleep', call_tree.target.full_name)

    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(2, method.total_time, 0.02)
    assert_in_delta(0, method.wait_time, 0.02)
    assert_in_delta(2, method.self_time, 0.02)
    assert_in_delta(0, method.children_time, 0.02)

    assert_equal(1, method.call_trees.callers.length)
    call_tree = method.call_trees.callers[0]
    assert_equal('StartStopTest#method3', call_tree.parent.target.full_name)

    assert_equal(0, method.call_trees.callees.length)
  end
end
