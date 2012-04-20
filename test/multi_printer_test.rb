#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'tmpdir'

# Test data
#     A
#    / \
#   B   C
#        \
#         B

class MSTPT
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

class MultiPrinterTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_all_profiles_can_be_created
    start_time = Time.now
    RubyProf.start
    5.times{MSTPT.new.a}
    result = RubyProf.stop
    end_time = Time.now
    expected_time = end_time - start_time
    stack = graph = nil
    assert_nothing_raised { stack, graph = print(result) }
    re = Regexp.new('
\s*<table>
\s*<tr>
\s*<th>Thread ID</th>
\s*<th>Total Time</th>
\s*</tr>
\s*
\s*<tr>
\s*<td><a href="#\d+">\d+</a></td>
\s*<td>([\.0-9]+)</td>
\s*</tr>
\s*
\s*</table>')
    assert graph =~ re
    display_time = $1.to_f
    assert_in_delta expected_time, display_time, 0.005
  end

  private
  def print(result)
    test = caller.first =~ /in `(.*)'/ ? $1 : "test"
    path = Dir::tmpdir
    profile = "ruby_prof_#{test}"
    printer = RubyProf::MultiPrinter.new(result)
    printer.print(:path => path, :profile => profile,
                  :threshold => 0, :min_percent => 0, :title => "ruby_prof #{test}")
    if RUBY_PLATFORM =~ /darwin/ && ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT']=="1"
      system("open '#{printer.stack_profile}'")
    end
    if GC.respond_to?(:dump_file_and_line_info)
      GC.start
      GC.dump_file_and_line_info("heap.dump")
    end
    [File.open(printer.stack_profile){|f|f.read}, File.open(printer.graph_profile){|f|f.read}]
  end
end
