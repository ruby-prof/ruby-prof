#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class InverseCallTreeTest < TestCase
  INVERSE_DEPTH = 5

  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  INVERSE_DEPTH.times do |i|
    if i == 0
      define_method("method_#{i}") do
        sleep_amount = (i + 1) * 0.05
        RubyProf.start
        sleep(sleep_amount)
      end
    else
      define_method("method_#{i}") do
        method_name = "method_#{i-1}"
        sleep_amount = (i + 1) * 0.05
        self.send(method_name.to_sym)
        sleep(sleep_amount)
      end
    end
  end

  def test_inverse
    method_name = "method_#{INVERSE_DEPTH - 1}"
    self.send(method_name.to_sym)
    result = profile = RubyProf.stop

    printer = RubyProf::CallInfoPrinter.new(result)
    File.open('c:/temp/call_tree.txt', 'wb') do |file|
      printer.print(file)
    end

    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open('c:/temp/graph.html', 'wb') do |file|
      printer.print(file)
    end

    printer = RubyProf::GraphPrinter.new(result)
    File.open('c:/temp/graph.txt', 'wb') do |file|
      printer.print(file)
    end

    printer = RubyProf::CallStackPrinter.new(result)
    File.open('c:/temp/call_stack.html', 'wb') do |file|
      printer.print(file)
    end

    assert_equal(1, profile.threads.count)

    thread = profile.threads.first
    assert_in_delta(0.25, thread.total_time, 0.015)

    top_methods = thread.top_methods.sort
    assert_equal(2, top_methods.count)
    assert_equal("BasicTest#start", top_methods[0].full_name)
    assert_equal("BasicTest#test_leave_method", top_methods[1].full_name)

    assert_equal(4, thread.methods.length)
    methods = profile.threads.first.methods.sort

    # Check times
    assert_equal("<Class::RubyProf::C1>#hello", methods[0].full_name)
    assert_in_delta(0.1, methods[0].total_time, 0.015)
    assert_in_delta(0.0,  methods[0].wait_time, 0.015)
    assert_in_delta(0.0,  methods[0].self_time, 0.015)

    assert_equal("BasicTest#start", methods[1].full_name)
    assert_in_delta(0.1, methods[1].total_time, 0.015)
    assert_in_delta(0.0, methods[1].wait_time, 0.015)
    assert_in_delta(0.0, methods[1].self_time, 0.015)

    assert_equal("BasicTest#test_leave_method", methods[2].full_name)
    assert_in_delta(0.15, methods[2].total_time, 0.015)
    assert_in_delta(0.0, methods[2].wait_time, 0.015)
    assert_in_delta(0.0, methods[2].self_time, 0.015)

    assert_equal("Kernel#sleep", methods[3].full_name)
    assert_in_delta(0.25, methods[3].total_time, 0.015)
    assert_in_delta(0.0, methods[3].wait_time, 0.015)
    assert_in_delta(0.25, methods[3].self_time, 0.015)
  end
end
