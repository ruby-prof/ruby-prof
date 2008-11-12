#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'

class ExceptionsTest < Test::Unit::TestCase
  def test_profile
    result = begin
      RubyProf.profile do 
        raise(RuntimeError, 'Test error')
      end
    rescue => e
    end    
    assert_not_nil(result)
  end
end
