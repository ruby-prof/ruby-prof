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
    assert_equal(2, result.threads.keys.length) # this should pass...
  end

  def test_thread_identity
    RubyProf.start
    thread = Thread.new do
      sleep(1)
    end
    thread.join
    result = RubyProf.stop

    thread_ids = result.threads.keys.sort
    threads = [Thread.current, thread]
    assert_equal(2, thread_ids.length) # should pass

    assert(thread_ids.include?(threads[0].object_id))
    assert(thread_ids.include?(threads[1].object_id))

    assert_instance_of(Thread, ObjectSpace._id2ref(thread_ids[0]))
    assert(threads.include?(ObjectSpace._id2ref(thread_ids[0])))

    assert_instance_of(Thread, ObjectSpace._id2ref(thread_ids[1]))
    assert(threads.include?(ObjectSpace._id2ref(thread_ids[1])))
  end

  def test_thread_timings
        RubyProf.start
    thread = Thread.new do
      sleep 0 # force it to hit thread.join, below, first
      # thus forcing sleep(1), below, to be counted as (wall) self_time
      # since we currently count time "in some other thread" as self.wait_time
      # for whatever reason
      sleep(1)
    end
    thread.join
    result = RubyProf.stop

    # Check background thread
    assert_equal(2, result.threads.length)
    methods = result.threads[thread.object_id].sort.reverse
    assert_equal(2, methods.length)

    method = methods[0]
    assert_equal('ThreadTest#test_thread_timings', method.full_name)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.05)
    assert_in_delta(0, method.self_time, 0.01)
    assert_in_delta(0, method.wait_time, 0.01)
    assert_in_delta(1, method.children_time, 0.01)
    assert_equal(1, method.call_infos.length)
    call_info = method.call_infos[0]
    assert_equal('ThreadTest#test_thread_timings', call_info.call_sequence)
    assert_equal(1, call_info.children.length)

    method = methods[1]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(2, method.called)
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
    # the sub calls to Object#new, when popped,
    # cause the parent frame to be created for method #test_thread_timings, which means a +1 when it's popped in the end
    # xxxx a test that shows it the other way, too (never creates parent frame--if that's even possible)
    assert_equal(1, method.called)
    assert_in_delta(1, method.total_time, 0.01)
    assert_in_delta(0, method.self_time, 0.05)
    assert_in_delta(0, method.wait_time, 0.05)
    assert_in_delta(1, method.children_time, 0.01)

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

  # useless test
  def test_thread_back_and_forth
        result = RubyProf.profile do
                a = Thread.new { 100_000.times { sleep 0 }}
                b = Thread.new { 100_000.times { sleep 0 }}
                a.join
                b.join
        end
        assert result.threads.values.flatten.sort[-1].total_time < 10 # 10s. Amazingly, this can fail in OS X at times. Amazing.
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
