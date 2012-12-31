#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class BasicTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_running
    assert(!RubyProf.running?)
    RubyProf.start
    assert(RubyProf.running?)
    RubyProf.stop
    assert(!RubyProf.running?)
  end

  def test_double_profile
    RubyProf.start
    assert_raise(RuntimeError) do
      RubyProf.start
    end
    RubyProf.stop
  end

  def test_no_block
    assert_raise(ArgumentError) do
      RubyProf.profile
    end
  end

  def test_traceback
    RubyProf.start
    assert_raise(NoMethodError) do
      RubyProf.xxx
    end

    RubyProf.stop
  end

  def test_pause_seq
    p = RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start ; assert !p.paused?
    p.pause ; assert p.paused?
    p.resume; assert !p.paused?
    p.pause ; assert p.paused?
    p.pause ; assert p.paused?
    p.resume; assert !p.paused?
    p.resume; assert !p.paused?
    p.stop  ; assert !p.paused?
  end

  def test_pause_block
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start
    p.pause
    assert p.paused?

    times_block_invoked = 0
    retval= p.resume{
      times_block_invoked += 1
      120 + times_block_invoked
    }
    assert_equal 1, times_block_invoked
    assert p.paused?

    assert_equal 121, retval, "resume() should return the result of the given block."

    p.stop
  end

  def test_pause_block_with_error
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start
    p.pause
    assert p.paused?

    begin
      p.resume{ raise }
      flunk 'Exception expected.'
    rescue
      assert p.paused?
    end

    p.stop
  end

  def test_resume_when_not_paused
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start ; assert !p.paused?
    p.resume; assert !p.paused?
    p.stop  ; assert !p.paused?
  end
end
