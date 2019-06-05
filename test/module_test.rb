#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

# Need to use wall time for this test due to the sleep calls
RubyProf::measure_mode = RubyProf::WALL_TIME

module Foo
  def Foo::sleep_wait
    sleep(0.5)
  end
end

module Bar
  def Bar::sleep_wait
    sleep(0.5)
    Foo::sleep_wait
  end

  def sleep_wait
    sleep(0.5)
    Bar::sleep_wait
  end
end

include Bar

class ModuleTest < TestCase
  def test_nested_modules
    result = RubyProf.profile do
      sleep_wait
    end

    methods = result.threads.first.methods

    # Length should be 5
    assert_equal(5, methods.length)

    # these methods should be in there... (hard to tell order though).
    for name in ['ModuleTest#test_nested_modules','Bar#sleep_wait','Kernel#sleep','<Module::Bar>#sleep_wait','<Module::Foo>#sleep_wait']
      assert methods.map(&:full_name).include?( name )
    end
  end
end
