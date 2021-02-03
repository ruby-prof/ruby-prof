# encoding: UTF-8

require 'bundler/setup'
require 'minitest/autorun'

# Disable minitest parallel tests. The problem is the thread switching will change test results
# (self vs wait time)
if Gem::Version.new(Minitest::VERSION) > Gem::Version.new('5.11.3')
  ENV["MT_CPU"] = "0" # Newer versions minitest
else
  ENV["N"] = "0" # Older versions of minitest
end

require 'ruby-prof'

class TestCase < Minitest::Test
end
