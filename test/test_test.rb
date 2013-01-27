#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)
require 'ruby-prof/test'

class SampleTestClass
  include RubyProf::Test
end

class TestTest < Test::Unit::TestCase
  def setup
    @sample_test_class = SampleTestClass
    @sample_test       = @sample_test_class.new
    @profile_options   = @sample_test_class::PROFILE_OPTIONS
  end

  def test_profile_options
    assert_equal [RubyProf::PROCESS_TIME], @profile_options[:measure_modes]
    assert_equal [RubyProf::FlatPrinter, RubyProf::GraphHtmlPrinter], @profile_options[:printers]
    assert_equal 0.05, @profile_options[:min_percent]
    assert_equal 10, @profile_options[:count]
  end

  def test_output_dir
    assert_equal @profile_options[:output_dir], @sample_test.output_dir
  end

  def test_measure_mode_name
    [
      [RubyProf::PROCESS_TIME, 'process_time'],
      [RubyProf::WALL_TIME, 'wall_time'],
      [RubyProf::MEMORY, 'memory'],
      [RubyProf::ALLOCATIONS, 'allocations'],
      ['another_measure_mode', 'measureanother_measure_mode']
    ].each do |measure_pair|
      measure_mode = measure_pair[0]
      measure_mode_name = measure_pair[1]
      assert_equal measure_mode_name, @sample_test.measure_mode_name(measure_mode)
    end
  end
end

