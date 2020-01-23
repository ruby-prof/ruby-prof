#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fiber'
require 'timeout'
require 'set'

# --  Tests ----
class FiberTest < TestCase
  def fiber_test
    @fiber_ids << Fiber.current.object_id
    enum = Enumerator.new do |yielder|
      [1,2].each do |x|
        @fiber_ids << Fiber.current.object_id
        sleep 0.1
        yielder.yield x
      end
    end
    while true
      begin
        enum.next
      rescue StopIteration
        break
      end
    end
    sleep 0.1
  end

  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
    @fiber_ids  = Set.new
    @root_fiber = Fiber.current.object_id
    @thread_id  = Thread.current.object_id
  end

  def test_fibers
    result  = RubyProf.profile { fiber_test }

    profiled_fiber_ids = result.threads.map(&:fiber_id)
    assert_equal(2, result.threads.length)
    assert_equal([@thread_id], result.threads.map(&:id).uniq)
    assert_equal(@fiber_ids, Set.new(profiled_fiber_ids))

    assert profiled_fiber_ids.include?(@root_fiber)
    assert(root_fiber_profile = result.threads.detect{|t| t.fiber_id == @root_fiber})
    assert(enum_fiber_profile = result.threads.detect{|t| t.fiber_id != @root_fiber})
    assert_in_delta(0.33, root_fiber_profile.total_time, 0.05)
    assert_in_delta(0.33, enum_fiber_profile.total_time, 0.05)

    methods = result.threads[0].methods.sort.reverse
    assert_equal(12, methods.count)

    method = methods[0]
    assert_equal('FiberTest#test_fibers', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.33, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0.33, method.children_time, 0.05)

    method = methods[1]
    assert_equal('FiberTest#fiber_test', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.33, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0.33, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Enumerator#next', method.full_name)
    assert_equal(3, method.called)
    assert_in_delta(0.22, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0.22, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.11, method.total_time, 0.05)
    assert_in_delta(0.11, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    # Since these methods have such short times their order is a bit indeterminate
    method = methods.detect {|method| method.full_name == 'Class#new'}
    assert_equal('Class#new', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5.0')
    method = methods.detect {|method| method.full_name == 'Set#<<'}
    assert_equal('Set#<<', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)
    end

    method = methods.detect {|method| method.full_name == 'Module#==='}
    assert_equal('Module#===', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == 'Kernel#object_id'}
    assert_equal('Kernel#object_id', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == '<Class::Fiber>#current'}
    assert_equal('<Class::Fiber>#current', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == 'Exception#exception'}
    assert_equal('Exception#exception', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == 'Exception#backtrace'}
    assert_equal('Exception#backtrace', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == 'Enumerator#initialize'}
    assert_equal('Enumerator#initialize', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    methods = result.threads[1].methods.sort.reverse

    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6.0')
      assert_equal(10, methods.count)
    else
      assert_equal(11, methods.count)
    end

    method = methods[0]
    assert_equal('RubyProf::Profile#_inserted_parent_', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.33, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0.11, method.wait_time, 0.05)
    assert_in_delta(0.22, method.children_time, 0.05)

    method = methods[1]
    assert_equal('Enumerator#each', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.22, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0.22, method.children_time, 0.05)

    method = methods[2]
    assert_equal('Enumerator::Generator#each', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.22, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0.22, method.children_time, 0.05)

    method = methods[3]
    assert_equal('Array#each', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0.22, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0.22, method.children_time, 0.05)

    method = methods[4]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0.22, method.total_time, 0.05)
    assert_in_delta(0.22, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    # Since these methods have such short times their order is a bit indeterminate
    method = methods.detect {|method| method.full_name == 'Exception#initialize'}
    assert_equal('Exception#initialize', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.6.0')
      method = methods.detect {|method| method.full_name == 'Set#<<'}
      assert_equal('Set#<<', method.full_name)
      assert_equal(2, method.called)
      assert_in_delta(0, method.total_time, 0.05)
      assert_in_delta(0, method.self_time, 0.05)
      assert_in_delta(0, method.wait_time, 0.05)
      assert_in_delta(0, method.children_time, 0.05)
    end

    method = methods.detect {|method| method.full_name == 'Kernel#object_id'}
    assert_equal('Kernel#object_id', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == 'Enumerator::Yielder#yield'}
    assert_equal('Enumerator::Yielder#yield', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == '<Class::Fiber>#current'}
    assert_equal('<Class::Fiber>#current', method.full_name)
    assert_equal(2, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)

    method = methods.detect {|method| method.full_name == 'Numeric#eql?'}
    assert_equal('Numeric#eql?', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(0, method.children_time, 0.05)
  end

  def test_merged_fibers
    result  = RubyProf.profile(merge_fibers: true) { fiber_test }
    assert_equal(1, result.threads.length)

    thread = result.threads.first
    assert_equal(thread.id, thread.fiber_id)
    assert_in_delta(0.3, thread.total_time, 0.05)

    assert(method_next = thread.methods.detect{|m| m.full_name == "Enumerator#next"})
    assert(method_each = thread.methods.detect{|m| m.full_name == "Enumerator#each"})

    assert_in_delta(0.2, method_next.total_time, 0.05)
    assert_in_delta(0.2, method_each.total_time, 0.05)
  end
end
