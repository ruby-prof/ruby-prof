#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require File.dirname(__FILE__) + '/prime'

# --  Tests ----
class PrintersTest < Test::Unit::TestCase
  
  def go
    run_primes
  end
  
  def setup
    RubyProf::measure_mode = RubyProf::WALL_TIME # WALL_TIME so we can use sleep in our test
    @result = RubyProf.profile do
      run_primes
      go
    end
    
  end
    
  def test_printers
    printer = RubyProf::FlatPrinter.new(@result)
    printer.print(STDOUT)
    
    printer = RubyProf::FlatPrinterWithLineNumbers.new(@result)
    printer.print(STDOUT)
    
    printer = RubyProf::GraphHtmlPrinter.new(@result)
    printer.print
    
    printer = RubyProf::GraphPrinter.new(@result)
    printer.print
    
    printer = RubyProf::CallTreePrinter.new(@result)
    printer.print(STDOUT)    
    # we should get here    
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
		  # 1.9
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

    assert_match(/fn=Object::find_primes/i, output)
    assert_match(/events: wall_time/i, output)
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
      puts klass
      printer = klass.new(result)
      out = ''
      output = printer.print(out, :min_percent => 0.00000001 )
      assert_match(/do_nothing/, out)      
    end
    
  end    
  
  
  
end
