#!/usr/bin/env ruby
# encoding: UTF-8

require './test_helper'

# Make sure this works with no class or method
result = RubyProf.profile do
  sleep 1
end

methods = result.threads.values.first
global_method = methods.sort_by {|method| method.full_name}.first
if global_method.full_name != 'Global#[No method]'
  raise(RuntimeError, "Wrong method name.  Expected: Global#[No method].  Actual: #{global_method.full_name}")
end
