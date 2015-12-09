#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'stringio'
require 'fileutils'

# --- code to be tested ---
module PRGT
  extend self

  def f(n)
    n.times { sleep 0.1 }
  end

  def g(n)
    n.times { sleep 0.2 }
  end

  def run
    2.times { f(2); g(4) }
  end
end

# --- expected test output ---
=begin
Measure Mode: wall_time
Thread ID: 70238775664960
Fiber ID: 70238784046840
Total Time: 2.040249824523926
Sort by: total_time

  %total   %self      total       self       wait      child            calls    Name
--------------------------------------------------------------------------------
 100.00%   0.00%      2.040      0.000      0.000      2.040                1      PrintingRecursiveGraphTest#setup
                      2.040      0.000      0.000      2.040              1/1      PRGT#run
--------------------------------------------------------------------------------
                      2.040      0.000      0.000      2.040              1/1      PrintingRecursiveGraphTest#setup
 100.00%   0.00%      2.040      0.000      0.000      2.040                1      PRGT#run
                      2.040      0.000      0.000      2.040              1/5      Integer#times
--------------------------------------------------------------------------------
                      0.409      0.000      0.000      0.409              2/5      Prgt#f
                      1.631      0.000      0.000      1.631              2/5      PRGT#g
                      2.040      0.000      0.000      2.040              1/5      PRGT#run
 100.00%   0.00%      2.040      0.000      0.000      2.040                5     *Integer#times
                      2.040      2.040      0.000      0.000            12/12      Kernel#sleep
                      1.631      0.000      0.000      1.631              2/2      PRGT#g
                      0.409      0.000      0.000      0.409              2/2      PRGT#f
--------------------------------------------------------------------------------
                      2.040      2.040      0.000      0.000            12/12      Integer#times
  99.99%  99.99%      2.040      2.040      0.000      0.000               12      Kernel#sleep
--------------------------------------------------------------------------------
                      1.631      0.000      0.000      1.631              2/2      Integer#times
  79.94%   0.00%      1.631      0.000      0.000      1.631                2      PRGT#g
                      1.631      0.000      0.000      1.631              2/5      Integer#times
--------------------------------------------------------------------------------
                      0.409      0.000      0.000      0.409              2/2      Integer#times
  20.05%   0.00%      0.409      0.000      0.000      0.409                2      PRGT#f
                      0.409      0.000      0.000      0.409              2/5      Integer#times

* indicates recursively called methods
=end

class PrintingRecursiveGraphTest < TestCase
  include PrinterTestHelper

  def setup
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    RubyProf::measure_mode = RubyProf::WALL_TIME
    @result = RubyProf.profile do
      PRGT.run
    end
  end

  def test_printing_rescursive_graph
    printer = RubyProf::GraphPrinter.new(@result)

    buffer = ''
    printer.print(StringIO.new(buffer))

    puts buffer if ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1"

    parsed_output = MetricsArray.parse(buffer)

    assert( integer_times  = parsed_output.metrics_for("*Integer#times") )

    actual_parents = integer_times.parents.map(&:name)
    expected_parents = %w(PRGT#f PRGT#g PRGT#run)
    assert_equal expected_parents, actual_parents

    actual_children = integer_times.children.map(&:name)
    expected_children = %w(Kernel#sleep PRGT#g PRGT#f)
    assert_equal expected_children, actual_children

    assert( fp = integer_times.parent("PRGT#f") )
    assert_in_delta(fp.total, fp.child, 0.01)
    assert_equal("2/5", fp.calls)

    assert( gp = integer_times.parent("PRGT#g") )
    assert_in_delta(gp.total, gp.child, 0.01)
    assert_equal("2/5", gp.calls)

    assert( rp = integer_times.parent("PRGT#run") )
    assert_in_delta(rp.total, rp.child, 0.01)
    assert_equal("1/5", rp.calls)

    assert_in_delta(4*fp.total, gp.total, 0.05)
    assert_in_delta(fp.total + gp.total, rp.total, 0.05)
    assert_in_delta(integer_times.metrics.total, rp.total, 0.05)

    assert( fc = integer_times.child("PRGT#f") )
    assert_in_delta(fc.total, fc.child, 0.01)
    assert_equal("2/2", fc.calls)

    assert( gc = integer_times.child("PRGT#g") )
    assert_in_delta(gc.total, gc.child, 0.01)
    assert_equal("2/2", gc.calls)

    assert( ks = integer_times.child("Kernel#sleep") )
    assert_in_delta(ks.total, ks.self_t, 0.01)
    assert_equal("12/12", ks.calls)

    assert_in_delta(4*fc.total, gc.total, 0.05)
    assert_in_delta(fp.total + gc.total, ks.total, 0.05)
    assert_in_delta(integer_times.metrics.total, ks.total, 0.05)
  end
end
