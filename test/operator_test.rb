#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path("../test_helper", __FILE__)

class Operators
  def self.should_be_called_by_main
  end

  def self.main
    self.order
    should_be_called_by_main
  end

  def self.order1=(value)
  end

  def self.order1
  end

  def self.order
    self.order1 ||= :random
  end
end

tp = TracePoint.new(:call, :c_call, :return, :c_return) do |event|
  p [event.event, event.method_id]
end

tp.enable do
  Operators.main
end

# class OperatorTest < TestCase
#
#   def setup
#     # Need to use wall time for this test due to the sleep calls
#     RubyProf::measure_mode = RubyProf::WALL_TIME
#   end
#
#   def test_double_pipe_equal
#     result = RubyProf.profile do
#       Operators.main
#     end
#     printer = RubyProf::GraphHtmlPrinter.new(result)
#     File.open('/Users/cfis/graph.html', 'wb') do |file|
#       printer.print(file)
#     end
#   end
# end
