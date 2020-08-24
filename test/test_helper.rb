# encoding: UTF-8

# Disable minitest parallel tests. The problem is the thread switching will change test results
# (self vs wait time)
ENV["N"] = "0" # Older versions of minitest
ENV["MT_CPU"] = "0" # Newer versions minitest

require 'bundler/setup'
require 'minitest/autorun'
require 'ruby-prof'

class TestCase < Minitest::Test
end