#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# issue 137 is about correctly attributing time of recursive children

class RecursiveChildrenTest < TestCase
  class SlowClass
    def time_sink
      1234567890 ** 100 == 0
    end
  end

  class SlowSearcher
    def do_find(slow_objects)
      slow_objects.find(&:time_sink)
    end
  end

  class MainClass
    def self.main_method
      slow_objects = [SlowClass.new] * 100_000
      slow_searcher = SlowSearcher.new
      slow_searcher.do_find(slow_objects)
    end
  end

  include PrinterTestHelper

  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_simple
    result = RubyProf.profile do
      # make array each recursive
      [1].each do
        MainClass.main_method
      end
    end

    # methods = result.threads.first.methods.sort.reverse

    printer = RubyProf::GraphPrinter.new(result)

    buffer = ''
    printer.print(StringIO.new(buffer))

    puts buffer if ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1"

    parsed_output = MetricsArray.parse(buffer)

    assert( enum_find  = parsed_output.metrics_for("Enumerable#find") )
    assert( array_each = enum_find.child("Array#each") )

    assert_operator enum_find.metrics.total, :>=, array_each.total
    assert_operator enum_find.metrics.total, :>, 0
    assert_in_delta enum_find.metrics.total, array_each.total, 0.02
  end

end
