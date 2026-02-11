# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'stringio'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrintersTest < TestCase
  def setup
    super
    # WALL_TIME, PROCESS_TIME, ALLOCATIONS and MEMORY as types of measuremen
    measure_modes = {wall_time: RubyProf::WALL_TIME, process_time: RubyProf::PROCESS_TIME, allocations: RubyProf::ALLOCATIONS}

    @results = {}

    measure_modes.each do |key, value|
      @results[key] = RubyProf::Profile.profile(measure_mode: value) do
        run_primes(1000, 5000)
      end
    end
  end

  def test_printers
    output = ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1" ? STDOUT : StringIO.new

    printer = RubyProf::CallStackPrinter.new(@results[:wall_time])
    printer.print(output.string)

    printer = RubyProf::CallTreePrinter.new(@results[:wall_time])
    printer.print(:path => Dir.tmpdir)

    printer = RubyProf::FlatPrinter.new(@results[:wall_time])
    printer.print(output.string)

    printer = RubyProf::GraphHtmlPrinter.new(@results[:wall_time])
    printer.print(output.string)

    printer = RubyProf::GraphPrinter.new(@results[:wall_time])
    printer.print(output.string)
  end

  def test_print_to_files
    printer = RubyProf::DotPrinter.new(@results[:wall_time])
    File.open("#{Dir.tmpdir}/graph.dot", "w") {|f| printer.print(f)}

    printer = RubyProf::CallStackPrinter.new(@results[:wall_time])
    File.open("#{Dir.tmpdir}/stack.html", "w") {|f| printer.print(f, :application => "primes")}

    printer = RubyProf::MultiPrinter.new(@results[:wall_time])
    printer.print(:path => Dir.tmpdir, :profile => "multi", :application => "primes")

    ['graph.dot', 'multi.flat.txt', 'multi.graph.html', "multi.callgrind.out.#{$$}", 'multi.stack.html', 'stack.html'].each do |file_name|
      file_path = File.join(Dir.tmpdir, file_name)
      refute(File.empty?(file_path))
    end
  end

  def test_refuses_io_objects
    p = RubyProf::MultiPrinter.new(@results[:wall_time])
    begin
      p.print(STDOUT)
      flunk "should have raised an ArgumentError"
    rescue ArgumentError => e
      assert_match(/IO/, e.to_s)
    end
  end

  def test_refuses_non_hashes
    p = RubyProf::MultiPrinter.new (@results[:wall_time])
    begin
      p.print([])
      flunk "should have raised an ArgumentError"
    rescue ArgumentError => e
      assert_match(/hash/, e.to_s)
    end
  end

  def test_flat_string
    output = helper_test_flat_string(RubyProf::FlatPrinter)
    assert_match(/prime.rb/, output.string)
  end

  def helper_test_flat_string(klass)
    output = StringIO.new

    printer = klass.new(@results[:wall_time])
    printer.print(output.string)

    assert_match(/Thread ID: -?\d+/i, output.string)
    assert_match(/Fiber ID: -?\d+/i, output.string)
    assert_match(/Total: \d+\.\d+/i, output.string)
    assert_match(/Object#run_primes/i, output.string)
    output
  end

  def test_graph_html_string
    output = StringIO.new
    printer = RubyProf::GraphHtmlPrinter.new(@results[:wall_time])
    printer.print(output.string)

    assert_match(/<!DOCTYPE html>/i, output.string)
    assert_match( %r{<th>Total</th>}i, output.string)
    assert_match(/Object#run_primes/i, output.string)
  end

  def test_graph_string
    output = StringIO.new
    printer = RubyProf::GraphPrinter.new(@results[:wall_time])
    printer.print(output.string)

    assert_match(/Thread ID: -?\d+/i, output.string)
    assert_match(/Fiber ID: -?\d+/i, output.string)
    assert_match(/Total Time: \d+\.\d+/i, output.string)
    assert_match(/Object#run_primes/i, output.string)
  end

  def do_nothing
    start = Time.now
    while(Time.now == start)
    end
  end

  def test_all_with_small_percentiles
    result = RubyProf::Profile.profile do
      sleep 2
      do_nothing
    end

    # RubyProf::CallTreePrinter doesn't "do" a min_percent
    # RubyProf::FlatPrinter only outputs if self time > percent...
    for klass in [RubyProf::GraphPrinter, RubyProf::GraphHtmlPrinter]
      printer = klass.new(result)
      out = StringIO.new
      printer.print(out, :min_percent => 0.00000001)
      assert_match(/do_nothing/, out.string)
    end
  end

  def test_print_footer
    results_keys = [:wall_time, :process_time, :allocations]
    expected_matches = [
      "The percentage of time spent by this method relative to the total time in the entire program.",
      "The total time spent by this method and its children.",
      "The time spent by this method.",
      "The time spent by this method's children.",
      "The percentage of allocations made by this method relative to the total allocations in the entire program.",
      "The total number of allocations made by this method and its children.",
      "The number of allocations made by this method.",
      "The number of allocations made by this method's children.",
      "The percentage of memory used by this method relative to the total memory in the entire program.",
      "The total memory used by this method and its children.",
      "The memory used by this method.",
      "The memory used by this method's children."
    ]

    results_keys.each do |key|
      output = StringIO.new
      printer = RubyProf::GraphPrinter.new(@results[key])
      printer.print(output.string)

      case key
      when :wall_time, :process_time
        matches = expected_matches[0..3]
      when :allocations
        matches = expected_matches[4..7]
      end

      matches.each do |pattern|
        assert_match(pattern, output.string)
      end
    end
  end
end
