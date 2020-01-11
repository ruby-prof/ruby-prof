#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class LineNumbers
  def method_1
    method_2
    filler = 1
    method_3
  end

  def method_2
    filler = 1
    2.times do |i|
      filler = 2
      method_3
    end
  end

  def method_3
    sleep(0.4)
    method_4
  end

  def method_4
    sleep(1)
  end
end

# --  Tests ----
class LineNumbersTest < TestCase
  def test_function_line_no
    numbers = LineNumbers.new

    result = RubyProf.profile do
      numbers.method_1
    end

    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open('c:/temp/graph.html', 'wb') do |file|
      printer.print(file)
    end

    methods = result.threads.first.methods.sort.reverse
    methods.each do |method|
      puts method.full_name
    end

    assert_equal(7, methods.length)

    # Method 0
    method = methods[0]
    assert_equal('LineNumbersTest#test_function_line_no', method.full_name)
    assert_equal(37, method.line)

    assert_equal(0, method.call_infos.callers.count)

    assert_equal(1, method.call_infos.callees.count)
    call_info = method.call_infos.callees[0]
    assert_equal('LineNumbers#method_1', call_info.target.full_name)
    assert_equal(37, call_info.line)

    # Method 1
    method = methods[1]
    assert_equal('LineNumbers#method_1', method.full_name)
    assert_equal(7, method.line)

    assert_equal(1, method.call_infos.callers.count)
    call_info = method.call_infos.callers[0]
    assert_equal('LineNumbersTest#test_function_line_no', call_info.parent.target.full_name)
    assert_equal(37, call_info.line)

    assert_equal(2, method.call_infos.callees.count)
    call_info = method.call_infos.callees[0]
    assert_equal('LineNumbers#method_2', call_info.target.full_name)
    assert_equal(8, call_info.line)

    call_info = method.call_infos.callees[1]
    assert_equal('LineNumbers#method_3', call_info.target.full_name)
    assert_equal(10, call_info.line)

    # Method 2
    method = methods[2]
    assert_equal('LineNumbers#method_3', method.full_name)
    assert_equal(21, method.line)

    assert_equal(2, method.call_infos.callers.count)
    call_info = method.call_infos.callers[0]
    assert_equal('Integer#times', call_info.parent.target.full_name)
    assert_equal(17, call_info.line)

    call_info = method.call_infos.callers[1]
    assert_equal('LineNumbers#method_1', call_info.parent.target.full_name)
    assert_equal(10, call_info.line)

    assert_equal(2, method.call_infos.callees.count)
    call_info = method.call_infos.callees[0]
    assert_equal('Kernel#sleep', call_info.target.full_name)
    assert_equal(22, call_info.line)

    call_info = method.call_infos.callees[1]
    assert_equal('LineNumbers#method_4', call_info.target.full_name)
    assert_equal(23, call_info.line)

    # Method 3
    method = methods[3]
    assert_equal('Kernel#sleep', method.full_name)
    assert_equal(0, method.line)

    assert_equal(2, method.call_infos.callers.count)
    call_info = method.call_infos.callers[0]
    assert_equal('LineNumbers#method_3', call_info.parent.target.full_name)
    assert_equal(22, call_info.line)

    call_info = method.call_infos.callers[1]
    assert_equal('LineNumbers#method_4', call_info.parent.target.full_name)
    assert_equal(27, call_info.line)

    assert_equal(0, method.call_infos.callees.count)

    # Method 4
    method = methods[4]
    assert_equal('LineNumbers#method_4', method.full_name)
    assert_equal(26, method.line)

    assert_equal(1, method.call_infos.callers.count)
    call_info = method.call_infos.callers[0]
    assert_equal('LineNumbers#method_3', call_info.parent.target.full_name)
    assert_equal(23, call_info.line)

    assert_equal(1, method.call_infos.callees.count)
    call_info = method.call_infos.callees[0]
    assert_equal('Kernel#sleep', call_info.target.full_name)
    assert_equal(27, call_info.line)

    # Method 5
    method = methods[5]
    assert_equal('LineNumbers#method_2', method.full_name)
    assert_equal(13, method.line)

    assert_equal(1, method.call_infos.callers.count)
    call_info = method.call_infos.callers[0]
    assert_equal('LineNumbers#method_1', call_info.parent.target.full_name)
    assert_equal(8, call_info.line)

    assert_equal(1, method.call_infos.callees.count)
    call_info = method.call_infos.callees[0]
    assert_equal('Integer#times', call_info.target.full_name)
    assert_equal(15, call_info.line)

    # Method 6
    method = methods[6]
    assert_equal('Integer#times', method.full_name)
    assert_equal(0, method.line)

    assert_equal(1, method.call_infos.callers.count)
    call_info = method.call_infos.callers[0]
    assert_equal('LineNumbers#method_2', call_info.parent.target.full_name)
    assert_equal(15, call_info.line)

    assert_equal(1, method.call_infos.callees.count)
    call_info = method.call_infos.callees[0]
    assert_equal('LineNumbers#method_3', call_info.target.full_name)
    assert_equal(17, call_info.line)
  end
end
