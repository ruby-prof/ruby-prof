# encoding: UTF-8

# Disable minitest parallel tests. The problem is the thread switching will cahnge test results
# (self vs wait time)
ENV["N"] = "0"

require 'bundler/setup'
require 'minitest/autorun'
require 'ruby-prof'

class TestCase < Minitest::Test
end