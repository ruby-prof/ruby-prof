#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'
require 'prime'

# --  Tests ----
class PrimeTest< Test::Unit::TestCase
  def test_consistency
    result = RubyProf.profile do
      run_primes
    end
  end
end