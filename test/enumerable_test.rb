#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'

# --  Test for bug
# http://github.com/rdp/ruby-prof/issues#issue/12

class EnumerableTest < Test::Unit::TestCase
  def test_enumerable
    result = RubyProf.profile do
      3.times {  [1,2,3].any? {|n| n} }
    end
    assert result.threads.to_a.first[1].length == 4    
  end
end