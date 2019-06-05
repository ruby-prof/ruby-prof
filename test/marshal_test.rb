#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path("../test_helper", __FILE__)
require 'stringio'

class MarshalTest < TestCase
  def verify_profile(profile_1, profile_2)
    verify_threads(profile_1.threads, profile_2.threads)
  end

  def verify_threads(threads_1, threads_2)
    assert_equal(threads_1.count, threads_2.count)
    threads_1.count.times do |i|
      thread_1 = threads_1[i]
      thread_2 = threads_2[i]
      assert_nil(thread_2.id)
      assert_nil(thread_2.fiber_id)

      verify_methods(thread_1.methods, thread_2.methods)
    end
  end

  def verify_methods(methods_1, methods_2)
    assert_equal(methods_1.count, methods_2.count)

    methods_1.count.times do |i|
      method_1 = methods_1[i]
      method_2 = methods_2[i]

      assert_equal(method_1.klass, method_2.klass)
      assert_equal(method_1.klass_name, method_2.klass_name)
      assert_equal(method_1.method_name, method_2.method_name)
      assert_equal(method_1.full_name, method_2.full_name)
      assert_equal(method_1.method_id, method_2.method_id)

      assert_equal(method_1.recursive?, method_2.recursive?)
      assert_equal(method_1.calltree_name, method_2.calltree_name)

      assert_equal(method_1.source_klass, method_2.source_klass)
      assert_equal(method_1.source_file, method_2.source_file)
      assert_equal(method_1.line, method_2.line)

      verify_call_infos(method_1.callers, method_2.callers)
      verify_call_infos(method_1.callees, method_2.callees)
    end
  end

  def verify_call_infos(call_infos_1, call_infos_2)
    assert_equal(call_infos_1.count, call_infos_2.count)
    call_infos_1.count.times do |i|
      call_info_1 = call_infos_1[i]
      call_info_2 = call_infos_2[i]
      verify_call_info(call_info_1, call_info_2)
    end
  end

  def verify_call_info(call_info_1, call_info_2)
    assert_equal(call_info_1.parent, call_info_2.parent)
    assert_equal(call_info_1.target, call_info_2.target)

    assert_equal(call_info_1.total_time, call_info_2.total_time)
    assert_equal(call_info_1.self_time, call_info_2.self_time)
    assert_equal(call_info_1.wait_time, call_info_2.wait_time)

    assert_equal(call_info_1.called, call_info_2.called)

    assert_equal(call_info_1.recursive?, call_info_2.recursive?)
    assert_equal(call_info_1.depth, call_info_2.depth)
    assert_equal(call_info_1.line, call_info_2.line)
  end

  def test_marshal
    profile_1 = RubyProf.profile do
      1.times { RubyProf::C1.new.hello }
    end

    data = Marshal.dump(profile_1)
    profile_2 = Marshal.load(data)

    verify_profile(profile_1, profile_2)
  end

  # def test_printer
  #   profile_1 = RubyProf.profile do
  #     1.times { RubyProf::C1.new.hello }
  #   end
  #
  #   data = Marshal.dump(profile_1)
  #   profile_2 = Marshal.load(data)
  #
  #   printer_1 = RubyProf::GraphPrinter.new(profile_1)
  #   io_1 = StringIO.new
  #   printer_1.print(io_1)
  #   output_1 = io_1.string
  #   output_1 = output_1.gsub(/^Thread ID:.*$/, 'Thread ID: ')
  #   output_1 = output_1.gsub(/^Fiber ID:.*$/, 'Fiber ID: ')
  #
  #   printer_2 = RubyProf::GraphPrinter.new(profile_2)
  #   io_2 = StringIO.new
  #   printer_2.print(io_2)
  #   output_2 = io_2.string
  #
  #   assert_equal(output_1, output_2)
  # end
end
