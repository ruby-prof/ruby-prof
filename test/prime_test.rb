#!/usr/bin/env ruby
# encoding: UTF-8

require './test_helper'

# --  Tests ----
class PrimeTest< Test::Unit::TestCase
  def test_consistency
    result = RubyProf.profile do
      run_primes
    end
  end
end