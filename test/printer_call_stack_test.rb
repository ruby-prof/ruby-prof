#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrinterCallStackTest < TestCase
  def setup
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    RubyProf::measure_mode = RubyProf::WALL_TIME
    @result = RubyProf.profile do
      run_primes(1000, 5000)
    end
  end

  def test_graph_html_string
    output = ''
    printer = RubyProf::CallStackPrinter.new(@result)
    printer.print(output)

    assert_match(/<!DOCTYPE html>/i, output)
    assert_match(/Object#run_primes/i, output)
  end
end
