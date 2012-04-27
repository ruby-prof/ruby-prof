#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class PauseResumeTest < Test::Unit::TestCase

  # pause/resume in the same frame
  def test_pause_resume_1
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])

    p.start
    method_1a

    p.pause
    method_1b

    p.resume
    method_1c

    r= p.stop
    assert_in_delta(0.6, r.threads[0].methods.select{|m| m.full_name =~ /test_pause_resume_1$/}[0].total_time, 0.05)
  end
  def method_1a; sleep 0.2 end
  def method_1b; sleep 1   end
  def method_1c; sleep 0.4 end

  # pause in parent frame, resume in child
  def test_pause_resume_2
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])

    p.start
    method_2a

    p.pause
    sleep 0.5
    method_2b(p)

    r= p.stop
    assert_in_delta(0.6, r.threads[0].methods.select{|m| m.full_name =~ /test_pause_resume_2$/}[0].total_time, 0.05)
  end
  def method_2a; sleep 0.2 end
  def method_2b(p); sleep 0.5; p.resume; sleep 0.4 end

  # pause in child frame, resume in parent
  def test_pause_resume_3
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])

    p.start
    method_3a(p)

    sleep 0.5
    p.resume
    method_3b

    r= p.stop
    assert_in_delta(0.6, r.threads[0].methods.select{|m| m.full_name =~ /test_pause_resume_3$/}[0].total_time, 0.05)
  end
  def method_3a(p); sleep 0.2; p.pause; sleep 0.5 end
  def method_3b; sleep 0.4 end
end
