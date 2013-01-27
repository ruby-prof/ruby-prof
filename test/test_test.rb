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
  end

  def test_profile_options
    options = @sample_test_class::PROFILE_OPTIONS
    assert_equal [RubyProf::PROCESS_TIME], options[:measure_modes]
    assert_equal 10, options[:count]
    assert_equal [RubyProf::FlatPrinter, RubyProf::GraphHtmlPrinter], options[:printers]
    assert_equal 0.05, options[:min_percent]
  end
end

