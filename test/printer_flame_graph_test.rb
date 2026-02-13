#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'
require 'stringio'
require 'tmpdir'
require_relative 'prime'

# --  Tests ----
class PrinterFlameGraphTest < TestCase
  def setup
    super
    # WALL_TIME so we can use sleep in our test and get same measurements on linux and windows
    @result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
      run_primes(1000, 5000)
    end
  end

  def test_flame_graph_string
    output = StringIO.new
    printer = RubyProf::FlameGraphPrinter.new(@result)
    printer.print(output)

    assert_match(/<!DOCTYPE html>/i, output.string)
    assert_match(/flame-svg/, output.string)
    assert_match(/Object#run_primes/i, output.string)
  end

  def test_flame_graph_stringio
    output = StringIO.new
    printer = RubyProf::FlameGraphPrinter.new(@result)
    printer.print(output)

    result = output.string
    assert_match(/<!DOCTYPE html>/i, result)
    assert_match(/flame-svg/, result)
    assert_match(/Object#run_primes/i, result)
  end

  def test_flame_graph_contains_svg_elements
    output = StringIO.new
    printer = RubyProf::FlameGraphPrinter.new(@result)
    printer.print(output)

    assert_match(/<svg/, output.string)
    assert_match(/renderNode/, output.string)
  end

  def test_flame_graph_contains_json_data
    output = StringIO.new
    printer = RubyProf::FlameGraphPrinter.new(@result)
    printer.print(output)

    # The template embeds thread data as JSON
    assert_match(/"name"/, output.string)
    assert_match(/"value"/, output.string)
    assert_match(/"children"/, output.string)
  end

  def test_flame_graph_custom_title
    output = StringIO.new
    printer = RubyProf::FlameGraphPrinter.new(@result)
    printer.print(output, title: "Custom Flame Graph")

    assert_match(/Custom Flame Graph/, output.string)
  end

  def test_flame_graph_file_output
    Dir.mktmpdir do |dir|
      path = File.join(dir, "flame_graph.html")
      File.open(path, "wb") do |file|
        printer = RubyProf::FlameGraphPrinter.new(@result)
        printer.print(file)
      end

      content = File.read(path)
      assert_match(/<!DOCTYPE html>/i, content)
      assert_match(/Object#run_primes/i, content)
    end
  end
end
