#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'
require 'tmpdir'

# Test data
#     A
#    / \
#   B   C
#        \
#         B

class STPT
  def a
    100.times{b}
    300.times{c}
    c;c;c
  end

  def b
    sleep 0
  end

  def c
    5.times{b}
  end
end

class StackPrinterTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_stack_can_be_printed
    start_time = Time.now
    RubyProf.start
    5.times{STPT.new.a}
    result = RubyProf.stop
    end_time = Time.now
    expected_time = end_time - start_time

    file_contents = nil
    assert_nothing_raised { file_contents = print(result) }
    assert file_contents =~ /Thread: (\d+) \(100\.00% ~ ([.0-9]+)\)/
    actual_time = $2.to_f
    difference = (expected_time-actual_time).abs
    assert_in_delta(expected_time, actual_time, 0.01)
  end

  def test_method_elimination
    RubyProf.start
    5.times{STPT.new.a}
    result = RubyProf.stop
    assert_nothing_raised {
      # result.dump
      result.eliminate_methods!([/Integer#times/])
      # $stderr.puts "================================"
      # result.dump
      print(result)
    }
  end

  private
  def print(result)
    test = caller.first =~ /in `(.*)'/ ? $1 : "test"
    testfile_name = "#{Dir::tmpdir}/ruby_prof_#{test}.html"
    printer = RubyProf::CallStackPrinter.new(result)
    File.open(testfile_name, "w") {|f| printer.print(f, :threshold => 0, :min_percent => 0, :title => "ruby_prof #{test}")}
    system("open '#{testfile_name}'") if RUBY_PLATFORM =~ /darwin/ && ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT']=="1"
    File.open(testfile_name, "r"){|f| f.read}
  end
end
