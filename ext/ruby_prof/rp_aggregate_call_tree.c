/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_aggregate_call_tree.h"

VALUE cRpAggregateCallTree;

void prof_aggregate_call_tree_mark(void* data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)data;

    if (call_tree->source_file != Qnil)
        rb_gc_mark(call_tree->source_file);
}

static void prof_aggregate_call_tree_ruby_gc_free(void* data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)data;
    prof_call_tree_free(call_tree);
}

VALUE prof_aggregate_call_tree_wrap(prof_call_tree_t* call_tree)
{
    if (call_tree->object == Qnil)
    {
        call_tree->object = Data_Wrap_Struct(cRpAggregateCallTree, prof_aggregate_call_tree_mark, prof_aggregate_call_tree_ruby_gc_free, call_tree);
    }
    return call_tree->object;
}

void rp_init_aggregate_call_tree()
{
    // AggregateCallTree
    cRpAggregateCallTree = rb_define_class_under(mProf, "AggregateCallTree", cRpCallTree);
    rb_undef_method(CLASS_OF(cRpAggregateCallTree), "new");
}
