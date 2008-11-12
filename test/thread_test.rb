#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require 'timeout'

# --  Tests ----
class ThreadTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_thread_count
    RubyProf.start

    thread = Thread.new do
      sleep(1)
    end

    thread.join
    result = RubyProf.stop

    assert_equal(2, result.threads.keys.length)
  end

  def test_thread_identity
    RubyProf.start

    thread = Thread.new do
      sleep(1)
    end

    thread.join
    result = RubyProf.stop

    thread_ids = result.threads.keys.sort
    threads = [Thread.current, thread].sort_by {|thread| thread.object_id}

    assert_equal(threads[0].object_id, thread_ids[0])
    assert_equal(threads[1].object_id, thread_ids[1])

    assert_instance_of(Thread, ObjectSpace._id2ref(thread_ids[0]))
    assert_equal(threads[0], ObjectSpace._id2ref(thread_ids[0]))

    assert_instance_of(Thread, ObjectSpace._id2ref(thread_ids[1]))
    assert_equal(threads[1], ObjectSpace._id2ref(thread_ids[1]))
  end

  def test_thread_timings
    RubyProf.start

    thread = Thread.new do
      sleep(1)
    end

    thread.join

    result = RubyProf.stop

    # Check background thread
    methods = result.threads[thread.object_id].sort.reverse
    assert_equal(2, methods.length)

    method = methods[0]
    assert_equal('ThreadTest#test_thread_timings', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(1, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)
    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[1]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(1.0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings->Kernel#sleep', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    # Check foreground thread
    methods = result.threads[Thread.current.object_id].sort.reverse
    assert_equal(4, methods.length)
    methods = methods.sort.reverse

    method = methods[0]
    assert_equal('ThreadTest#test_thread_timings', method.full_name)
    assert_equal(0, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(1.0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings', call_info.call_sequence)
    assert_equal(2, call_info.children.length)

    method = methods[1]
    assert_equal('Thread#join', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(1.0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings->Thread#join', call_info.call_sequence)
    assert_equal(0, call_info.children.length)

    method = methods[2]
    assert_equal('<Class::Thread>#new', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings-><Class::Thread>#new', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[3]
    assert_equal('Thread#initialize', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(0, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(0, method.children_time, 0.01)

    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings-><Class::Thread>#new->Thread#initialize', call_info.call_sequence)
    assert_equal(0, call_info.children.length)
  end
  
  def test_thread
    result = RubyProf.profile do
      begin
        status = Timeout::timeout(2) do
          while true
            next
          end
        end
      rescue Timeout::Error
      end
    end
  end
end