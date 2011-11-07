#!/usr/bin/env ruby
# encoding: UTF-8

require './test_helper'

class MeasureProcessTimeTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::PROCESS_TIME
  end

  def test_mode
    RubyProf::measure_mode = RubyProf::PROCESS_TIME
    assert_equal(RubyProf::PROCESS_TIME, RubyProf::measure_mode)
  end

  def test_class_methods
    result = RubyProf.profile do
      RubyProf::C1.hello
    end

    # Length should be 3:
    #   MeasureProcessTimeTest#test_class_methods
    #   <Class::RubyProf::C1>#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    puts methods[0].total_time
    
    assert_equal(3, methods.length)

    # Check the names
    assert_equal('MeasureProcessTimeTest#test_class_methods', methods[0].full_name)
    assert_equal('<Class::RubyProf::C1>#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.0, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.0, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.0, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.0, methods[2].self_time, 0.01)
  end

  def test_instance_methods
    result = RubyProf.profile do
      RubyProf::C1.new.hello
    end

    # Methods called
    #   MeasureProcessTimeTest#test_instance_methods
    #   Class.new
    #   Class:Object#allocate
    #   for Object#initialize
    #   C1#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(6, methods.length)
    names = methods.map(&:full_name)
    assert(names.include?('MeasureProcessTimeTest#test_instance_methods'))
    assert(names.include?('RubyProf::C1#hello'))
    assert(names.include?('Kernel#sleep'))
    assert(names.include?('Class#new'))
    assert(names.include?("<Class::#{RubyProf::PARENT}>#allocate"))
    assert(names.include?("#{RubyProf::PARENT}#initialize"))

    # Check times
    assert_in_delta(0, methods[0].total_time, 0.02)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0, methods[1].total_time, 0.02)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)

    assert_in_delta(0, methods[2].total_time, 0.02)
    assert_in_delta(0, methods[2].wait_time, 0.02)
    assert_in_delta(0, methods[2].self_time, 0.02)

    assert_in_delta(0, methods[3].total_time, 0.01)
    assert_in_delta(0, methods[3].wait_time, 0.01)
    assert_in_delta(0, methods[3].self_time, 0.01)

    assert_in_delta(0, methods[4].total_time, 0.01)
    assert_in_delta(0, methods[4].wait_time, 0.01)
    assert_in_delta(0, methods[4].self_time, 0.01)

    assert_in_delta(0, methods[5].total_time, 0.01)
    assert_in_delta(0, methods[5].wait_time, 0.01)
    assert_in_delta(0, methods[5].self_time, 0.01)
  end

  def test_module_methods
    result = RubyProf.profile do
      RubyProf::C2.hello
    end

    # Methods:
    #   MeasureProcessTimeTest#test_module_methods
    #   M1#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(3, methods.length)

    assert_equal('MeasureProcessTimeTest#test_module_methods', methods[0].full_name)
    assert_equal('RubyProf::M1#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.1, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.02)
    assert_in_delta(0, methods[0].self_time, 0.02)

    assert_in_delta(0.1, methods[1].total_time, 0.1)
    assert_in_delta(0, methods[1].wait_time, 0.02)
    assert_in_delta(0, methods[1].self_time, 0.02)

    assert_in_delta(0.1, methods[2].total_time, 0.1)
    assert_in_delta(0, methods[2].wait_time, 0.02)
    assert_in_delta(0.1, methods[2].self_time, 0.1)
  end

  def test_module_instance_methods
    result = RubyProf.profile do
      RubyProf::C2.new.hello
    end

    # Methods:
    #   MeasureProcessTimeTest#test_module_instance_methods
    #   Class#new
    #   <Class::Object>#allocate
    #   Object#initialize
    #   M1#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(6, methods.length)
    names = methods.map(&:full_name)
    assert(names.include?('MeasureProcessTimeTest#test_module_instance_methods'))
    assert(names.include?('RubyProf::M1#hello'))
    assert(names.include?('Kernel#sleep'))
    assert(names.include?('Class#new'))
    assert(names.include?("<Class::#{RubyProf::PARENT}>#allocate"))
    assert(names.include?("#{RubyProf::PARENT}#initialize"))

    # Check times
    assert_in_delta(0, methods[0].total_time, 0.1)
    assert_in_delta(0, methods[0].wait_time, 0.1)
    assert_in_delta(0, methods[0].self_time, 0.1)

    assert_in_delta(0, methods[1].total_time, 0.02)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0, methods[2].total_time, 0.02)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0, methods[2].self_time, 0.02)

    assert_in_delta(0, methods[3].total_time, 0.01)
    assert_in_delta(0, methods[3].wait_time, 0.01)
    assert_in_delta(0, methods[3].self_time, 0.01)

    assert_in_delta(0, methods[4].total_time, 0.01)
    assert_in_delta(0, methods[4].wait_time, 0.01)
    assert_in_delta(0, methods[4].self_time, 0.01)

    assert_in_delta(0, methods[5].total_time, 0.01)
    assert_in_delta(0, methods[5].wait_time, 0.01)
    assert_in_delta(0, methods[5].self_time, 0.01)
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

    methods = result.threads.values.first.sort.reverse
    assert_equal(2, methods.length)

    assert_equal('MeasureProcessTimeTest#test_singleton', methods[0].full_name)
    assert_equal('<Object::RubyProf::C3>#hello', methods[1].full_name)

    assert_in_delta(0, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)
  end
end
