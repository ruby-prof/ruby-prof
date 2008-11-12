#!/usr/bin/env ruby

require 'test/unit'
require 'ruby-prof'

class C1
  def C1.hello
    sleep(0.1)
  end
  
  def hello
    sleep(0.2)
  end
end

module M1
  def hello
    sleep(0.3)
  end
end

class C2
  include M1
  extend M1
end

class C3
  def hello
    sleep(0.4)
  end
end

module M4
  def hello
    sleep(0.5)
  end
end

module M5
  include M4
  def goodbye
    hello
  end
end

class C6
  include M5
  def test
    goodbye
  end
end

class BasicTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_running
    assert(!RubyProf.running?)
    RubyProf.start
    assert(RubyProf.running?)
    RubyProf.stop
    assert(!RubyProf.running?)
  end

  def test_double_profile
    RubyProf.start
    assert_raise(RuntimeError) do
      RubyProf.start
    end

    assert_raise(RuntimeError) do
      RubyProf.profile do
        puts 1
      end
    end
    RubyProf.stop
  end

  def test_no_block
    assert_raise(ArgumentError) do
      RubyProf.profile
    end
  end

  def test_class_methods
    result = RubyProf.profile do
      C1.hello
    end

    # Length should be 3:
    #   BasicTest#test_class_methods
    #   <Class::C1>#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(3, methods.length)

    # Check the names
    assert_equal('BasicTest#test_class_methods', methods[0].full_name)
    assert_equal('<Class::C1>#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.1, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.1, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.1, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.1, methods[2].self_time, 0.01)
  end

  def test_instance_methods
    result = RubyProf.profile do
      C1.new.hello
    end

    # Methods called
    #   BasicTest#test_instance_methods
    #   Class.new
    #   Class:Object#allocate
    #   for Object#initialize
    #   C1#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(6, methods.length)

    assert_equal('BasicTest#test_instance_methods', methods[0].full_name)
    assert_equal('C1#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_equal('Class#new', methods[3].full_name)
    assert_equal('<Class::Object>#allocate', methods[4].full_name)
    assert_equal('Object#initialize', methods[5].full_name)

    # Check times
    assert_in_delta(0.2, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.2, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.2, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.2, methods[2].self_time, 0.01)

    assert_in_delta(0, methods[3].total_time, 0.01)
    assert_in_delta(0, methods[3].wait_time, 0.01)
    assert_in_delta(0, methods[3].self_time, 0.01)

    assert_in_delta(0, methods[4].total_time, 0.01)
    assert_in_delta(0, methods[4].wait_time, 0.01)
    assert_in_delta(0, methods[4].self_time, 0.01)

    assert_in_delta(0, methods[5].total_time, 0.01)
    assert_in_delta(0, methods[5].wait_time, 0.01)
    assert_in_delta(0, methods[5].self_time, 0.01)
  end

  def test_module_methods
    result = RubyProf.profile do
      C2.hello
    end

    # Methods:
    #   BasicTest#test_module_methods
    #   M1#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(3, methods.length)

    assert_equal('BasicTest#test_module_methods', methods[0].full_name)
    assert_equal('M1#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.3, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.3, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.3, methods[2].self_time, 0.01)
  end

  def test_module_instance_methods
    result = RubyProf.profile do
      C2.new.hello
    end

    # Methods:
    #   BasicTest#test_module_instance_methods
    #   Class#new
    #   <Class::Object>#allocate
    #   Object#initialize
    #   M1#hello
    #   Kernel#sleep

    methods = result.threads.values.first.sort.reverse
    assert_equal(6, methods.length)

    assert_equal('BasicTest#test_module_instance_methods', methods[0].full_name)
    assert_equal('M1#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)
    assert_equal('Class#new', methods[3].full_name)
    assert_equal('<Class::Object>#allocate', methods[4].full_name)
    assert_equal('Object#initialize', methods[5].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.3, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.3, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.3, methods[2].self_time, 0.01)

    assert_in_delta(0, methods[3].total_time, 0.01)
    assert_in_delta(0, methods[3].wait_time, 0.01)
    assert_in_delta(0, methods[3].self_time, 0.01)

    assert_in_delta(0, methods[4].total_time, 0.01)
    assert_in_delta(0, methods[4].wait_time, 0.01)
    assert_in_delta(0, methods[4].self_time, 0.01)

    assert_in_delta(0, methods[5].total_time, 0.01)
    assert_in_delta(0, methods[5].wait_time, 0.01)
    assert_in_delta(0, methods[5].self_time, 0.01)
  end

  def test_singleton
    c3 = C3.new

    class << c3
      def hello
      end
    end

    result = RubyProf.profile do
      c3.hello
    end

    methods = result.threads.values.first.sort.reverse
    assert_equal(2, methods.length)

    assert_equal('BasicTest#test_singleton', methods[0].full_name)
    assert_equal('<Object::C3>#hello', methods[1].full_name)

    assert_in_delta(0, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)
  end

  def test_traceback
    RubyProf.start
    assert_raise(NoMethodError) do
      RubyProf.xxx
    end

    RubyProf.stop
  end
end