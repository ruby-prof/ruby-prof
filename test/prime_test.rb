#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# --  Tests ----
class PrimeTest< Test::Unit::TestCase
  def test_consistency
    RubyProf.profile do
      run_primes
    end
  end
end