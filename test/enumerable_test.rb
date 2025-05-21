#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# --  Test for bug
# http://github.com/rdp/ruby-prof/issues#issue/12

class EnumerableTest < TestCase
  def test_enumerable
    result = RubyProf::Profile.profile do
      3.times {  [1,2,3].any? {|n| n} }
    end
    methods = if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')
                %w(EnumerableTest#test_enumerable Integer#times Array#any?)
                %w(EnumerableTest#test_enumerable Integer#times Kernel#block_given? Integer#< Array#any? Integer#succ)
              elsif Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.4')
                %w(EnumerableTest#test_enumerable Integer#times Kernel#block_given? Integer#< Array#any? Integer#succ)
              else
                %w(EnumerableTest#test_enumerable Integer#times Integer#< Array#any? Integer#succ)
              end
    assert_equal(methods, result.threads.first.methods.map(&:full_name))
  end
end
