#!/usr/bin/env ruby
# encoding: UTF-8

require './test_helper'


class DynamicMethodTest < Test::Unit::TestCase
  def test_dynamic_method
    result = RubyProf.profile do
      2.times { require 'test_helper.rb' }
    end


    # Methods called
    #   BasicTest#test_instance_methods
    #   Class.new
    #   Class:Object#allocate
    #   for Object#initialize
    #   C1#hello
    #   Kernel#sleep

      printer = RubyProf::FlatPrinterWithLineNumbers.new(result)
      printer.print(STDOUT)

    #methods = result.threads.values.first.sort.reverse
    #puts methods

#    assert_equal(6, methods.length)
#    names = methods.map(&:full_name)
#    assert_equal('BasicTest#test_instance_methods', names[0])
#    assert_equal('C1#hello', names[1])
#    assert_equal('Kernel#sleep', names[2])
#    assert_equal('Class#new', names[3])
#    # order can differ
#    assert(names.include?("<Class::#{PARENT}>#allocate"))
#    assert(names.include?("#{PARENT}#initialize"))
#
#    # Check times
#    assert_in_delta(0.2, methods[0].total_time, 0.02)
#    assert_in_delta(0, methods[0].wait_time, 0.02)
#    assert_in_delta(0, methods[0].self_time, 0.02)
#
#    assert_in_delta(0.2, methods[1].total_time, 0.02)
#    assert_in_delta(0, methods[1].wait_time, 0.02)
#    assert_in_delta(0, methods[1].self_time, 0.02)
#
#    assert_in_delta(0.2, methods[2].total_time, 0.02)
#    assert_in_delta(0, methods[2].wait_time, 0.02)
#    assert_in_delta(0.2, methods[2].self_time, 0.02)
#
#    assert_in_delta(0, methods[3].total_time, 0.01)
#    assert_in_delta(0, methods[3].wait_time, 0.01)
#    assert_in_delta(0, methods[3].self_time, 0.01)
#
#    assert_in_delta(0, methods[4].total_time, 0.01)
#    assert_in_delta(0, methods[4].wait_time, 0.01)
#    assert_in_delta(0, methods[4].self_time, 0.01)
#
#    assert_in_delta(0, methods[5].total_time, 0.01)
#    assert_in_delta(0, methods[5].wait_time, 0.01)
#    assert_in_delta(0, methods[5].self_time, 0.01)
  end
end
