#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path("../test_helper", __FILE__)

class AliasTest < TestCase
  class TestMe
    def some_method
      sleep(0.1)
    end

    alias :some_method_original :some_method
    def some_method
      some_method_original
    end
  end

  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  # This test only correct works on Ruby 2.5 and higher because - see:
  # https://bugs.ruby-lang.org/issues/12747
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5.0')
    def test_alias
      result = RubyProf.profile do
        TestMe.new.some_method
      end

      methods = result.threads.first.methods
      assert_equal(6, methods.count)

      # Method 0
      method = methods[0]
      assert_equal('AliasTest#test_alias', method.full_name)
      assert_equal(28, method.line)
      refute(method.recursive?)

      assert_equal(0, method.call_infos.callers.count)

      assert_equal(2, method.call_infos.callees.count)
      call_info = method.call_infos.callees[0]
      assert_equal('Class#new', call_info.target.full_name)
      assert_equal(28, call_info.line)

      call_info = method.call_infos.callees[1]
      assert_equal('AliasTest::TestMe#some_method', call_info.target.full_name)
      assert_equal(28, call_info.line)

      # Method 1
      method = methods[1]
      assert_equal('Class#new', method.full_name)
      assert_equal(0, method.line)
      refute(method.recursive?)

      assert_equal(1, method.call_infos.callers.count)
      call_info = method.call_infos.callers[0]
      assert_equal('AliasTest#test_alias', call_info.parent.target.full_name)
      assert_equal(28, call_info.line)

      assert_equal(1, method.call_infos.callees.count)
      call_info = method.call_infos.callees[0]
      assert_equal('BasicObject#initialize', call_info.target.full_name)
      assert_equal(0, call_info.line)

      # Method 2
      method = methods[2]
      assert_equal('BasicObject#initialize', method.full_name)
      assert_equal(0, method.line)
      refute(method.recursive?)

      assert_equal(1, method.call_infos.callers.count)
      call_info = method.call_infos.callers[0]
      assert_equal('Class#new', call_info.parent.target.full_name)
      assert_equal(0, call_info.line)

      assert_equal(0, method.call_infos.callees.count)

      # Method 3
      method = methods[3]
      assert_equal('AliasTest::TestMe#some_method', method.full_name)
      assert_equal(13, method.line)
      refute(method.recursive?)

      assert_equal(1, method.call_infos.callers.count)
      call_info = method.call_infos.callers[0]
      assert_equal('AliasTest#test_alias', call_info.parent.target.full_name)
      assert_equal(28, call_info.line)

      assert_equal(1, method.call_infos.callees.count)
      call_info = method.call_infos.callees[0]
      assert_equal('AliasTest::TestMe#some_method_original', call_info.target.full_name)
      assert_equal(14, call_info.line)

      # Method 4
      method = methods[4]
      assert_equal('AliasTest::TestMe#some_method_original', method.full_name)
      assert_equal(8, method.line)
      refute(method.recursive?)

      assert_equal(1, method.call_infos.callers.count)
      call_info = method.call_infos.callers[0]
      assert_equal('AliasTest::TestMe#some_method', call_info.parent.target.full_name)
      assert_equal(14, call_info.line)

      assert_equal(1, method.call_infos.callees.count)
      call_info = method.call_infos.callees[0]
      assert_equal('Kernel#sleep', call_info.target.full_name)
      assert_equal(9, call_info.line)

      # Method 5
      method = methods[5]
      assert_equal('Kernel#sleep', method.full_name)
      assert_equal(0, method.line)
      refute(method.recursive?)

      assert_equal(1, method.call_infos.callers.count)
      call_info = method.call_infos.callers[0]
      assert_equal('AliasTest::TestMe#some_method_original', call_info.parent.target.full_name)
      assert_equal(9, call_info.line)

      assert_equal(0, method.call_infos.callees.count)
    end
  end
end
