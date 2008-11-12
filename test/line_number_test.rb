#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require 'prime'

class LineNumbers
  def method1
    a = 3
  end
  
  def method2
    a = 3
    method1
  end
  
  def method3
    sleep(1)
  end
end

# --  Tests ----
class LineNumbersTest < Test::Unit::TestCase
  def test_function_line_no
    numbers = LineNumbers.new
    
    result = RubyProf.profile do
      numbers.method2
    end

    methods = result.threads.values.first.sort.reverse
    assert_equal(3, methods.length)
    
    method = methods[0]
    assert_equal('LineNumbersTest#test_function_line_no', method.full_name)
    assert_equal(27, method.line)
    
    method = methods[1]
    assert_equal('LineNumbers#method2', method.full_name)
    assert_equal(11, method.line)
    
    method = methods[2]
    assert_equal('LineNumbers#method1', method.full_name)
    assert_equal(7, method.line)
  end
  
  def test_c_function
    numbers = LineNumbers.new
    
    result = RubyProf.profile do
      numbers.method3
    end

    methods = result.threads.values.first.sort_by {|method| method.full_name}
    assert_equal(3, methods.length)

    # Methods:
    #   LineNumbers#method3
    #   LineNumbersTest#test_c_function
    #   Kernel#sleep

    method = methods[0]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(0, method.line)
    
    method = methods[1]
    assert_equal('LineNumbers#method3', method.full_name)
    assert_equal(16, method.line)
    
    method = methods[2]
    assert_equal('LineNumbersTest#test_c_function', method.full_name)
    assert_equal(50, method.line)
  end
end