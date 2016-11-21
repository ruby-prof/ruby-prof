#!/usr/bin/env ruby

require File.expand_path('../test_helper', __FILE__)

class MultiMeasureTest < TestCase
  def foo
  end

  def test_measure_modes
    measure_modes = [RubyProf::PROCESS_TIME, RubyProf::WALL_TIME]

    profile = RubyProf::Profile.new(measure_modes: measure_modes)

    assert_equal measure_modes, profile.measure_modes
  end

  def test_measure_values
    measure_modes = [RubyProf::PROCESS_TIME, RubyProf::WALL_TIME]

    profile = RubyProf::Profile.new(measure_modes: measure_modes)

    profile.start

    foo

    profile.stop

    call_info = profile.threads.first.methods.first.call_infos.first

    measure_values = call_info.measure_values

    assert_equal 2, measure_values.size

    measure_values.each do |val|
      assert_equal 3, val.size
    end
  end
end
