#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'

# Need to use wall time for this test due to the sleep calls
RubyProf::measure_mode = RubyProf::WALL_TIME

module Foo
  def Foo::hello
    sleep(0.5)
  end
end

module Bar
  def Bar::hello
    sleep(0.5)
    Foo::hello
  end
  
  def hello
    sleep(0.5)
    Bar::hello
  end
end

include Bar

class ModuleTest < Test::Unit::TestCase
  def test_nested_modules
    result = RubyProf.profile do
      hello
    end

    methods = result.threads.values.first.sort.reverse
      
    # Length should be 5
    assert_equal(5, methods.length)
    
    method = methods[0]
    assert_equal('ModuleTest#test_nested_modules', method.full_name)
    
    method = methods[1]
    assert_equal('Bar#hello', method.full_name)

    method = methods[2]
    assert_equal('Kernel#sleep', method.full_name)
    
    method = methods[3]
    assert_equal('<Module::Bar>#hello', method.full_name)
    
    method = methods[4]
    assert_equal('<Module::Foo>#hello', method.full_name)
  end 
end
