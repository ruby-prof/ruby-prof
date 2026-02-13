#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

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

class MultiPrinterTest < TestCase
  def test_refuses_positional_arguments
    # we don't need a real profile for this test
    p = RubyProf::MultiPrinter.new nil
    assert_raises(ArgumentError) do
      p.print(STDOUT)
    end
  end

  private

  def print(result)
    test = caller.first =~ /in `(.*)'/ ? $1 : "test"
    path = Dir.tmpdir
    profile = "ruby_prof_#{test}"
    printer = RubyProf::MultiPrinter.new(result)
    printer.print(path: path, profile: profile,
                  threshold: 0, min_percent: 0, title: "ruby_prof #{test}")
    if RUBY_PLATFORM =~ /darwin/ && ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT']=="1"
      system("open '#{printer.stack_profile}'")
    end
    [File.read(printer.stack_profile), File.read(printer.graph_profile)]
  end
end
