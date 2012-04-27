#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class PauseResumeTest < Test::Unit::TestCase

  def test_pause_resume
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])

    p.start
    method1

    p.pause
    method2

    p.resume
    method3

    r= p.stop
    assert_in_delta(0.6, r.threads[0].methods.select{|m| m.full_name =~ /test_pause_resume$/}[0].total_time, 0.05)
  end

  def method1; sleep 0.2 end
  def method2; sleep 1   end
  def method3; sleep 0.4 end
end
