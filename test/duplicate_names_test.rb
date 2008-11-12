#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'

class DuplicateNames < Test::Unit::TestCase
  def test_names
    result = RubyProf::profile do
      str = %{module Foo; class Bar; def foo; end end end}

      eval str
      Foo::Bar.new.foo
      DuplicateNames.class_eval {remove_const :Foo}

      eval str
      Foo::Bar.new.foo
      DuplicateNames.class_eval {remove_const :Foo}

      eval str
      Foo::Bar.new.foo
    end
    
    # There should be 3 foo methods
    methods = result.threads.values.first.sort.reverse
    
    methods = methods.select do |method|
      method.full_name == 'DuplicateNames::Foo::Bar#foo'
    end

    assert_equal(3, methods.length)
  end
end
