# encoding: UTF-8

require 'bundler/setup'
require 'ruby-prof'

# Disable minitest parallel tests. The problem is the thread switching will change test results
# (self vs wait time)
ENV["MT_CPU"] = "0" # New versions of minitest
ENV["N"] = "0" # Older versions of minitest

require 'minitest/autorun'
class TestCase < Minitest::Test
end
