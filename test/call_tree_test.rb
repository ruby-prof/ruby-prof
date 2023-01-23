# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)
require 'base64'

# Create a DummyClass with methods so we can create call trees in the test_merge method below
class DummyClass
  %i[root a b aa ab ba bb].each do |method_name|
    define_method(method_name) do
    end
  end
end


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

  def create_call_trees
    # Test merging of two call trees that look like this:
    #
    #          root            root
    #        /     \         /     \
    #       a       b       a       b
    #     /  \       \       \     / \
    #   aa   ab      bb      ab  ba  bb
    #

    # -------  Call Tree 1 ---------
    call_trees = DummyClass.instance_methods(false).inject(Hash.new) do |hash, method_name|
      method_info = RubyProf::MethodInfo.new(DummyClass, method_name)
      call_tree = RubyProf::CallTree.new(method_info)
      hash[method_name] = call_tree
      hash
    end

    # Setup parent children
    call_trees[:root].add_child(call_trees[:a])
    call_trees[:root].add_child(call_trees[:b])
    call_trees[:a].add_child(call_trees[:aa])
    call_trees[:a].add_child(call_trees[:ab])
    call_trees[:b].add_child(call_trees[:bb])

    # Setup times
    call_trees[:aa].measurement.total_time = 1.5
    call_trees[:aa].measurement.self_time = 1.5
    call_trees[:ab].measurement.total_time = 2.2
    call_trees[:ab].measurement.self_time = 2.2
    call_trees[:a].measurement.total_time = 3.7

    call_trees[:aa].target.measurement.total_time = 1.5
    call_trees[:aa].target.measurement.self_time = 1.5
    call_trees[:ab].target.measurement.total_time = 2.2
    call_trees[:ab].target.measurement.self_time = 2.2
    call_trees[:a].target.measurement.total_time = 3.7

    call_trees[:bb].measurement.total_time = 4.3
    call_trees[:bb].measurement.self_time = 4.3
    call_trees[:b].measurement.total_time = 4.3

    call_trees[:bb].target.measurement.total_time = 4.3
    call_trees[:bb].target.measurement.self_time = 4.3
    call_trees[:b].target.measurement.total_time = 4.3

    call_trees[:root].measurement.total_time = 8.0
    call_trees[:root].target.measurement.total_time = 8.0

    call_tree_1 = call_trees[:root]

    # -------  Call Tree 2 ---------
    call_trees = DummyClass.instance_methods(false).inject(Hash.new) do |hash, method_name|
      method_info = RubyProf::MethodInfo.new(DummyClass, method_name)
      call_tree = RubyProf::CallTree.new(method_info)
      hash[method_name] = call_tree
      hash
    end

    # Setup parent children
    call_trees[:root].add_child(call_trees[:a])
    call_trees[:root].add_child(call_trees[:b])
    call_trees[:a].add_child(call_trees[:ab])
    call_trees[:b].add_child(call_trees[:ba])
    call_trees[:b].add_child(call_trees[:bb])

    # Setup times
    call_trees[:ab].measurement.total_time = 0.4
    call_trees[:ab].measurement.self_time = 0.4
    call_trees[:a].measurement.total_time = 0.4

    call_trees[:ab].target.measurement.total_time = 0.4
    call_trees[:ab].target.measurement.self_time = 0.4
    call_trees[:a].target.measurement.total_time = 0.4

    call_trees[:ba].measurement.total_time = 0.9
    call_trees[:ba].measurement.self_time = 0.7
    call_trees[:ba].measurement.wait_time = 0.2
    call_trees[:bb].measurement.total_time = 2.3
    call_trees[:bb].measurement.self_time = 2.3
    call_trees[:b].measurement.total_time = 3.2

    call_trees[:ba].target.measurement.total_time = 0.9
    call_trees[:ba].target.measurement.self_time = 0.7
    call_trees[:ba].target.measurement.wait_time = 0.2
    call_trees[:bb].target.measurement.total_time = 2.3
    call_trees[:bb].target.measurement.self_time = 2.3
    call_trees[:b].target.measurement.total_time = 3.2

    call_trees[:root].measurement.total_time = 3.6
    call_trees[:root].target.measurement.total_time = 3.6

    call_tree_2 = call_trees[:root]

    return call_tree_1, call_tree_2
  end

  def test_merge
    call_tree_1, call_tree_2 = create_call_trees
    call_tree_1.merge(call_tree_2)

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
