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

    methods = result.threads.values.first

    # Length should be 5
    assert_equal(5, methods.length)

    # these methods should be in there... (hard to tell order though).
    for name in ['ModuleTest#test_nested_modules','Bar#hello','Kernel#sleep','<Module::Bar>#hello','<Module::Foo>#hello']
      assert methods.map(&:full_name).include?( name )
    end
  end
end
