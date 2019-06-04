#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class MeasureProcessTimeTest < TestCase
  def setup
    # Need to fix this for linux (windows works since PROCESS_TIME is WALL_TIME anyway)
    RubyProf::measure_mode = RubyProf::PROCESS_TIME
    GC.start
  end

  def test_mode
    assert_equal(RubyProf::PROCESS_TIME, RubyProf::measure_mode)
  end

  def test_process_time_enabled_defined
    assert(defined?(RubyProf::PROCESS_TIME_ENABLED))
  end

  def test_class_methods
    result = RubyProf.profile do
      RubyProf::C1.hello
    end

    thread = result.threads.first
    assert_in_delta(0.1, thread.total_time, 0.02)

    top_methods = thread.top_methods
    assert_equal(1, top_methods.count)
    assert_equal("MeasureProcessTimeTest#test_class_methods", top_methods[0].full_name)

    # Length should be 3:
    #   MeasureProcessTimeTest#test_class_methods
    #   <Class::RubyProf::C1>#hello
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check the names
    assert_equal('MeasureProcessTimeTest#test_class_methods', methods[0].full_name)
    assert_equal('<Class::RubyProf::C1>#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.1, methods[0].total_time, 0.02)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0.1, methods[1].total_time, 0.02)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)

    assert_in_delta(0.1, methods[2].total_time, 0.02)
    assert_in_delta(0, methods[2].wait_time, 0.02)
    assert_in_delta(0.1, methods[2].self_time, 0.02)
  end

  def test_instance_methods
    result = RubyProf.profile do
      RubyProf::C1.new.hello
    end

    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open('c:/temp/graph.html', 'wb') do |file|
      printer.print(file)
    end

    thread = result.threads.first
    assert_in_delta(0.2, thread.total_time, 0.02)

    top_methods = thread.top_methods
    assert_equal(1, top_methods.count)
    assert_equal("MeasureProcessTimeTest#test_instance_methods", top_methods[0].full_name)

    # Methods called
    #   MeasureProcessTimeTest#test_instance_methods
    #   Class.new
    #   BasicObject#initialize
    #   C1#hello
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)
    names = methods.map(&:full_name)
    assert_equal('MeasureProcessTimeTest#test_instance_methods', names[0])
    assert_equal('RubyProf::C1#hello', names[1])
    assert_equal('Kernel#sleep', names[2])
    assert_equal('Class#new', names[3])

    # order can differ
    assert(names.include?("#{RubyProf.parent_object}#initialize"))

    # Check times
    assert_in_delta(0.2, methods[0].total_time, 0.02)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0.2, methods[1].total_time, 0.02)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)

    assert_in_delta(0.2, methods[2].total_time, 0.02)
    assert_in_delta(0, methods[2].wait_time, 0.02)
    assert_in_delta(0.2, methods[2].self_time, 0.02)

    assert_in_delta(0, methods[3].total_time, 0.02)
    assert_in_delta(0, methods[3].wait_time, 0.02)
    assert_in_delta(0, methods[3].self_time, 0.02)

    assert_in_delta(0, methods[4].total_time, 0.02)
    assert_in_delta(0, methods[4].wait_time, 0.02)
    assert_in_delta(0, methods[4].self_time, 0.02)
  end

  def test_module_methods
    result = RubyProf.profile do
      RubyProf::C2.hello
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.02)

    top_methods = thread.top_methods
    assert_equal(1, top_methods.count)
    assert_equal("MeasureProcessTimeTest#test_module_methods", top_methods[0].full_name)

    # Methods:
    #   MeasureProcessTimeTest#test_module_methods
    #   M1#hello
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    assert_equal('MeasureProcessTimeTest#test_module_methods', methods[0].full_name)
    assert_equal('RubyProf::M1#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0.3, methods[1].total_time, 0.1)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)

    assert_in_delta(0.3, methods[2].total_time, 0.1)
    assert_in_delta(0, methods[2].wait_time, 0.02)
    assert_in_delta(0.3, methods[2].self_time, 0.1)
  end

  def test_module_instance_methods
    result = RubyProf.profile do
      RubyProf::C2.new.hello
    end

    thread = result.threads.first
    assert_in_delta(0.3, thread.total_time, 0.02)

    top_methods = thread.top_methods
    assert_equal(1, top_methods.count)
    assert_equal("MeasureProcessTimeTest#test_module_instance_methods", top_methods[0].full_name)

    # Methods:
    #   MeasureProcessTimeTest#test_module_instance_methods
    #   Class#new
    #   <Class::Object>#allocate
    #   Object#initialize
    #   M1#hello
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(5, methods.length)
    names = methods.map(&:full_name)
    assert_equal('MeasureProcessTimeTest#test_module_instance_methods', names[0])
    assert_equal('RubyProf::M1#hello', names[1])
    assert_equal('Kernel#sleep', names[2])
    assert_equal('Class#new', names[3])

    # order can differ
    assert(names.include?("#{RubyProf.parent_object}#initialize"))

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.1)
    assert_in_delta(0, methods[0].self_time, 0.1)

    assert_in_delta(0.3, methods[1].total_time, 0.02)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)

    assert_in_delta(0.3, methods[2].total_time, 0.02)
    assert_in_delta(0, methods[2].wait_time, 0.02)
    assert_in_delta(0.3, methods[2].self_time, 0.02)

    assert_in_delta(0, methods[3].total_time, 0.02)
    assert_in_delta(0, methods[3].wait_time, 0.02)
    assert_in_delta(0, methods[3].self_time, 0.02)

    assert_in_delta(0, methods[4].total_time, 0.02)
    assert_in_delta(0, methods[4].wait_time, 0.02)
    assert_in_delta(0, methods[4].self_time, 0.02)
  end

  def test_singleton
    c3 = RubyProf::C3.new

    class << c3
      def hello
      end
    end

    result = RubyProf.profile do
      c3.hello
    end

    thread = result.threads.first
    assert_in_delta(0.0, thread.total_time, 0.02)

    top_methods = thread.top_methods
    assert_equal(1, top_methods.count)
    assert_equal("MeasureProcessTimeTest#test_singleton", top_methods[0].full_name)

    methods = result.threads.first.methods.sort.reverse
    assert_equal(2, methods.length)

    assert_equal('MeasureProcessTimeTest#test_singleton', methods[0].full_name)
    assert_equal('<Object::RubyProf::C3>#hello', methods[1].full_name)

    assert_in_delta(0, methods[0].total_time, 0.02)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0, methods[1].total_time, 0.02)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)
  end

  def test_waiting_for_threads_does_accumulate
    background_thread = nil
    result = RubyProf.profile do
      background_thread = Thread.new{ sleep 0.1 }
      background_thread.join
    end

    # check number of threads
    assert_equal(2, result.threads.length)
    fg, bg = result.threads
    assert(fg.methods.map(&:full_name).include?("Thread#join"))
    assert(bg.methods.map(&:full_name).include?("Kernel#sleep"))
    assert_in_delta(0.1, fg.total_time, 0.02)
    assert_in_delta(0.1, fg.wait_time, 0.02)
    assert_in_delta(0.1, bg.total_time, 0.02)
  end

  def test_sleeping_does_accumulate
    result = RubyProf.profile do
      sleep 0.1
    end
    methods = result.threads.first.methods.sort.reverse
    assert_equal(["MeasureProcessTimeTest#test_sleeping_does_accumulate", "Kernel#sleep"], methods.map(&:full_name))
    assert_in_delta(0.1, methods[1].total_time, 0.02)
    assert_equal(0, methods[1].wait_time)
    assert_in_delta(0.1, methods[1].self_time, 0.02)
  end
end
