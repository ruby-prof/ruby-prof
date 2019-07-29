# encoding: UTF-8

require "rubygems"
gem "minitest"
require 'singleton'

# To make testing/debugging easier, test within this source tree versus an installed gem
dir = File.dirname(__FILE__)
root = File.expand_path(File.join(dir, '..'))
lib = File.expand_path(File.join(root, 'lib'))
ext = File.expand_path(File.join(root, 'ext', 'ruby_prof'))

$LOAD_PATH << lib
$LOAD_PATH << ext

require 'ruby-prof'

# Disable minitest parallel tests. The problem is the thread switching will cahnge test results
# (self vs wait time)
ENV["N"] = "0"
require 'minitest/autorun'

class TestCase < Minitest::Test
end