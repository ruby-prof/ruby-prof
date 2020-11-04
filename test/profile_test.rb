#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class ProfileTest < TestCase
  def test_measure_mode
    profile = RubyProf::Profile.new(:measure_mode => RubyProf::PROCESS_TIME)
    assert_equal(RubyProf::PROCESS_TIME, profile.measure_mode)
  end

  def test_measure_mode_string
    profile = RubyProf::Profile.new(:measure_mode => RubyProf::PROCESS_TIME)
    assert_equal("process_time", profile.measure_mode_string)
  end
end
