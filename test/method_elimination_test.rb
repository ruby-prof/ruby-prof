#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'
require 'tmpdir'

# Test data
#     A
#    / \
#   B   C
#        \
#         B

class ESTPT
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

class MethodEliminationTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_setting_parent
    result = RubyProf.profile do
      1000.times { 1+1 }
    end
    method_infos = result.threads.values.first
    assert(m1 = method_infos[0])
    assert(c1 = m1.call_infos.first)
    assert_equal(c1, c1.parent = c1)
    assert_equal c1, c1.parent
  end

  def test_methods_can_be_eliminated
    RubyProf.start
    5.times{ESTPT.new.a}
    result = RubyProf.stop
    # result.dump
    eliminated = result.eliminate_methods!([/Integer#times/])
    # puts eliminated.inspect
    # result.dump
    eliminated.each do |m|
      assert_method_has_been_eliminated(result, m)
    end
  end

  private
  def assert_method_has_been_eliminated(result, eliminated_method)
    result.threads.each do |thread_id, methods|
      methods.each do |method|
        method.call_infos.each do |ci|
          assert(ci.target != eliminated_method, "broken self")
          assert(ci.parent.target != eliminated_method, "broken parent") if ci.parent
          ci.children.each do |callee|
            assert(callee.target != eliminated_method, "broken kid")
          end
        end
      end
    end
  end
end
