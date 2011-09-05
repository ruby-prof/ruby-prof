#!/usr/bin/env ruby
# encoding: UTF-8

require './test_helper'

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
