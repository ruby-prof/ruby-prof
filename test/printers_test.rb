#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require File.dirname(__FILE__) + '/prime'
require 'stringio'
require 'fileutils'
require 'rubygems'

# --  Tests ----
class PrintersTest < Test::Unit::TestCase

  def go
    run_primes(1000)
  end

  def setup
    RubyProf::measure_mode = RubyProf::WALL_TIME # WALL_TIME so we can use sleep in our test and get same measurements on linux and doze
    @result = RubyProf.profile do
      begin
        run_primes(1000)
        go
      rescue => e
        p e
      end
    end

  end

  def test_printers
    assert_nothing_raised do
      output = ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1" ? STDOUT : StringIO.new('')

      printer = RubyProf::FlatPrinter.new(@result)
      printer.print(output)

      printer = RubyProf::FlatPrinterWithLineNumbers.new(@result)
      printer.print(output)

      printer = RubyProf::GraphHtmlPrinter.new(@result)
      printer.print(output)

      printer = RubyProf::GraphPrinter.new(@result)
      printer.print(output)

      printer = RubyProf::CallTreePrinter.new(@result)
      printer.print(output)
      output_dir = 'examples2'
      
      if ENV['SAVE_NEW_PRINTER_EXAMPLES']
        output_dir = 'examples'
      end
      FileUtils.mkdir_p output_dir
      
      printer = RubyProf::DotPrinter.new(@result)
      File.open("#{output_dir}/graph.dot", "w") {|f| printer.print(f)}

      printer = RubyProf::CallStackPrinter.new(@result)
      File.open("#{output_dir}/stack.html", "w") {|f| printer.print(f, :application => "primes")}

      printer = RubyProf::MultiPrinter.new(@result)
      printer.print(:path => "#{output_dir}", :profile => "multi", :application => "primes")
      for file in ['empty.png', 'graph.dot', 'minus.png', 'multi.flat.txt', 'multi.graph.html', 'multi.grind.dat', 'multi.stack.html', 'plus.png', 'stack.html']
        existant_file = output_dir + '/' + file
        assert File.size(existant_file) > 0
      end
    end
  end

  def test_flat_string
    output = helper_test_flat_string RubyProf::FlatPrinter
    assert_no_match(/prime.rb/, output)
  end

  def helper_test_flat_string klass
    output = ''

    printer = klass.new(@result)
    printer.print(output)

    assert_match(/Thread ID: -?\d+/i, output)
    assert_match(/Total: \d+\.\d+/i, output)
    assert_match(/Object#run_primes/i, output)
    output
  end

  def test_flat_string_with_numbers
    output = helper_test_flat_string RubyProf::FlatPrinterWithLineNumbers
    assert_match(/prime.rb/, output)
    assert_no_match(/ruby_runtime:0/, output)
    assert_match(/called from/, output)

    # should combine common parents
    if RUBY_VERSION < '1.9'
      assert_equal(3, output.scan(/Object#is_prime/).length)
    else
      # 1.9 inlines it's  Fixnum#- so we don't see as many
      assert_equal(2, output.scan(/Object#is_prime/).length)
    end
    assert_no_match(/\.\/test\/prime.rb/, output) # don't use relative paths
  end

  def test_graph_html_string
    output = ''
    printer = RubyProf::GraphHtmlPrinter.new(@result)
    printer.print(output)

    assert_match( /DTD HTML 4\.01/i, output )
    assert_match( %r{<th>Total Time</th>}i, output )
    assert_match( /Object#run_primes/i, output )
  end

  def test_graph_string
    output = ''
    printer = RubyProf::GraphPrinter.new(@result)
    printer.print(output)

    assert_match( /Thread ID: -?\d+/i, output )
    assert_match( /Total Time: \d+\.\d+/i, output )
    assert_match( /Object#run_primes/i, output )
  end

  def test_call_tree_string
    output = ''
    printer = RubyProf::CallTreePrinter.new(@result)
    printer.print(output)
    assert_match(/fn=Object#find_primes/i, output)
    assert_match(/events: wall_time/i, output)
    assert_no_match(/d\d\d\d\d\d/, output) # old bug looked [in error] like Object::run_primes(d5833116)
  end

  def do_nothing
    start = Time.now
    while(Time.now == start)
    end
  end

  def test_all_with_small_percentiles

    result = RubyProf.profile do
      sleep 2
      do_nothing
    end

    # RubyProf::CallTreePrinter doesn't "do" a min_percent
    # RubyProf::FlatPrinter only outputs if self time > percent...
    # RubyProf::FlatPrinterWithLineNumbers same
    for klass in [ RubyProf::GraphPrinter, RubyProf::GraphHtmlPrinter]
      printer = klass.new(result)
      out = ''
      output = printer.print(out, :min_percent => 0.00000001 )
      assert_match(/do_nothing/, out)
    end

  end



end
