#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fiber'
require 'timeout'
require 'set'
require_relative './scheduler'

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0')

# --  Tests ----
class MergeTest < TestCase
  def worker1
    #puts "worker1 - start"
    sleep(0.5)
    #    puts "worker1 - end"
  end

  def worker2
    #puts "worker2 - start"
    sleep(0.5)
    sleep(0.5)
    #puts "worker2 - end"
  end

  def worker3
    #puts "worker3 - start"
    sleep(0.5)
    #puts "worker3 - end"
  end

  def concurrency_mergable
    scheduler = Scheduler.new
    Fiber.set_scheduler(scheduler)

    3.times do
      Fiber.schedule do
        worker1
      end
    end
    Fiber.scheduler.close
  end

  def concurrency_unmergable
    scheduler = Scheduler.new
    Fiber.set_scheduler(scheduler)

    3.times do |i|
      Fiber.schedule do
        method = "worker#{i + 1}".to_sym
        send(method)
      end
    end
    Fiber.scheduler.close
  end

  def test_times_no_merge
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_mergable }

    assert_equal(4, result.threads.size)

    result.threads.each do |thread|
      assert_in_delta(0.5, thread.call_tree.target.total_time, 0.2)
      assert_in_delta(0.0, thread.call_tree.target.self_time)
      assert_in_delta(0.0, thread.call_tree.target.wait_time)
      assert_in_delta(0.5, thread.call_tree.target.children_time, 0.2)
    end
  end

  def test_times_mergable
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_mergable }
    result.merge!

    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open("graph.html", "wb") do |file|
      printer.print(file)
    end

    assert_equal(2, result.threads.size)

    thread = result.threads[0]
    assert_in_delta(0.5, thread.call_tree.target.total_time, 0.2)
    assert_in_delta(0.0, thread.call_tree.target.self_time)
    assert_in_delta(0.0, thread.call_tree.target.wait_time)
    assert_in_delta(0.5, thread.call_tree.target.children_time, 0.2)

    thread = result.threads[1]
    assert_in_delta(1.5, thread.call_tree.target.total_time, 0.2)
    assert_in_delta(0.0, thread.call_tree.target.self_time)
    assert_in_delta(0.0, thread.call_tree.target.wait_time)
    assert_in_delta(1.5, thread.call_tree.target.children_time, 0.2)
  end

  def test_unmergable
    result  = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) { concurrency_unmergable }

    result.merge!

    printer = RubyProf::GraphPrinter.new(result)
    File.open("graph_merged.txt", "wb") do |file|
      printer.print(file, :min_percent => 0)
    end
  end
end
end
