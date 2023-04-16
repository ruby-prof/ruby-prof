# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)
require_relative './call_tree_builder'
require 'base64'

class CallTreeTest < Minitest::Test
  def test_initialize
    method_info = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree = RubyProf::CallTree.new(method_info)
    assert_equal(method_info, call_tree.target)
  end

  def test_measurement
    method_info = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree = RubyProf::CallTree.new(method_info)

    assert_equal(0, call_tree.total_time)
    assert_equal(0, call_tree.self_time)
    assert_equal(0, call_tree.wait_time)
    assert_equal(0, call_tree.children_time)
    assert_equal(0, call_tree.called)
  end

  def test_compare
    method_info_1 = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree_1 = RubyProf::CallTree.new(method_info_1)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree_2 = RubyProf::CallTree.new(method_info_2)
    assert_equal(0, call_tree_1 <=> call_tree_2)

    method_info_1 = RubyProf::MethodInfo.new(Base64, :decode64)
    call_tree_1 = RubyProf::CallTree.new(method_info_1)
    call_tree_1.measurement.total_time = 1
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree_2 = RubyProf::CallTree.new(method_info_2)
    assert_equal(1, call_tree_1 <=> call_tree_2)

    method_info_1 = RubyProf::MethodInfo.new(Base64, :decode64)
    call_tree_1 = RubyProf::CallTree.new(method_info_1)
    method_info_2 = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree_2 = RubyProf::CallTree.new(method_info_2)
    call_tree_2.measurement.total_time = 1
    assert_equal(-1, call_tree_1 <=> call_tree_2)
  end

  def test_to_s
    method_info = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree = RubyProf::CallTree.new(method_info)
    assert_equal("<RubyProf::CallTree - Base64#encode64>", call_tree.to_s)
  end

  def test_add_child
    method_info_parent = RubyProf::MethodInfo.new(Base64, :encode64)
    call_tree_parent = RubyProf::CallTree.new(method_info_parent)

    method_info_child = RubyProf::MethodInfo.new(Array, :pack)
    call_tree_child = RubyProf::CallTree.new(method_info_child)

    assert_equal(0, call_tree_parent.children.size)
    assert_nil(call_tree_child.parent)

    result = call_tree_parent.add_child(call_tree_child)
    assert_equal(1, call_tree_parent.children.size)
    assert_equal(call_tree_child, call_tree_parent.children.first)
    assert_equal(call_tree_child, result)
    assert_equal(call_tree_parent, call_tree_child.parent)
  end

  def test_add_child_gc
    GC.stress = true

    begin
      method_info_parent = RubyProf::MethodInfo.new(Base64, :encode64)
      call_tree_parent = RubyProf::CallTree.new(method_info_parent)

      method_info_child = RubyProf::MethodInfo.new(Array, :pack)
      call_tree_child = RubyProf::CallTree.new(method_info_child)
      call_tree_parent.add_child(call_tree_child)

      # Free the child first
      call_tree_child = nil
      GC.start

      # Now free the parent and make sure it doesn't free the child a second time
      call_tree_parent = nil
      GC.start

      assert(true)
    ensure
      GC.stress = false
    end
  end

  def test_merge
    call_tree_1 = create_call_tree_1
    call_tree_2 = create_call_tree_2
    call_tree_1.merge!(call_tree_2)

    # Root
    call_tree = call_tree_1
    assert_equal(:root, call_tree.target.method_name)
    assert_in_delta(11.6, call_tree.total_time, 0.00001)
    assert_in_delta(0, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(11.6, call_tree.children_time, 0.00001)

    assert_in_delta(11.6, call_tree.target.total_time, 0.00001)
    assert_in_delta(0, call_tree.target.self_time, 0.00001)
    assert_in_delta(0, call_tree.target.wait_time, 0.00001)
    assert_in_delta(11.6, call_tree.target.children_time, 0.00001)

    # a
    call_tree = call_tree_1.children[0]
    assert_equal(:a, call_tree.target.method_name)

    assert_in_delta(4.1, call_tree.total_time, 0.00001)
    assert_in_delta(0, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(4.1, call_tree.children_time, 0.00001)

    assert_in_delta(4.1, call_tree.target.total_time, 0.00001)
    assert_in_delta(0, call_tree.target.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.wait_time, 0.00001)
    assert_in_delta(4.1, call_tree.target.children_time, 0.00001)

    # aa
    call_tree = call_tree_1.children[0].children[0]
    assert_equal(:aa, call_tree.target.method_name)

    assert_in_delta(1.5, call_tree.total_time, 0.00001)
    assert_in_delta(1.5, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)

    assert_in_delta(1.5, call_tree.target.total_time, 0.00001)
    assert_in_delta(1.5, call_tree.target.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.children_time, 0.00001)

    # ab
    call_tree = call_tree_1.children[0].children[1]
    assert_equal(:ab, call_tree.target.method_name)

    assert_in_delta(2.6, call_tree.total_time, 0.00001)
    assert_in_delta(2.6, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)

    assert_in_delta(2.6, call_tree.target.total_time, 0.00001)
    assert_in_delta(2.6, call_tree.target.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.children_time, 0.00001)

    # b
    call_tree = call_tree_1.children[1]
    assert_equal(:b, call_tree.target.method_name)

    assert_in_delta(7.5, call_tree.total_time, 0.00001)
    assert_in_delta(0, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(7.5, call_tree.children_time, 0.00001)

    assert_in_delta(7.5, call_tree.target.total_time, 0.00001)
    assert_in_delta(0, call_tree.target.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.wait_time, 0.00001)
    assert_in_delta(7.5, call_tree.target.children_time, 0.00001)

    # bb
    call_tree = call_tree_1.children[1].children[0]
    assert_equal(:bb, call_tree.target.method_name)

    assert_in_delta(6.6, call_tree.total_time, 0.00001)
    assert_in_delta(6.6, call_tree.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)

    assert_in_delta(6.6, call_tree.target.total_time, 0.00001)
    assert_in_delta(6.6, call_tree.target.self_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.children_time, 0.00001)

    # ba
    call_tree = call_tree_1.children[1].children[1]
    assert_equal(:ba, call_tree.target.method_name)

    assert_in_delta(0.9, call_tree.total_time, 0.00001)
    assert_in_delta(0.7, call_tree.self_time, 0.00001)
    assert_in_delta(0.2, call_tree.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.children_time, 0.00001)

    assert_in_delta(0.9, call_tree.target.total_time, 0.00001)
    assert_in_delta(0.7, call_tree.target.self_time, 0.00001)
    assert_in_delta(0.2, call_tree.target.wait_time, 0.00001)
    assert_in_delta(0.0, call_tree.target.children_time, 0.00001)
  end
end
