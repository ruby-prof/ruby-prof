#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'timeout'
require 'set'
begin
  require 'fiber'
rescue LoadError
end

# --  Tests ----
# code for this test taken from FiberTest and modified
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
    result = RubyProf::Profile.profile(
      RubyProf::WALL_TIME, [], Thread.current, Fiber.current
    ) do
      fiber_test
    end

    profiled_fiber_ids = result.threads.map(&:fiber_id)
    assert_equal(1, result.threads.length)
    assert_equal([@thread_id], result.threads.map(&:id).uniq)

    # fibers from fiber_test() shouldn't show up
    assert_equal([Fiber.current.object_id], profiled_fiber_ids)
  end

end

