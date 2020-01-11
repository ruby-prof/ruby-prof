/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_aggregate_call_info.h"

VALUE cRpAggregateCallInfo;

void prof_aggregate_call_info_mark(void* data)
{
    prof_call_info_t* call_info = (prof_call_info_t*)data;

    if (call_info->source_file != Qnil)
        rb_gc_mark(call_info->source_file);
}

static void prof_aggregate_call_info_ruby_gc_free(void* data)
{
    prof_call_info_t* call_info = (prof_call_info_t*)data;
    prof_call_info_free(call_info);
}

VALUE prof_aggregate_call_info_wrap(prof_call_info_t* call_info)
{
    if (call_info->object == Qnil)
    {
        call_info->object = Data_Wrap_Struct(cRpAggregateCallInfo, prof_aggregate_call_info_mark, prof_aggregate_call_info_ruby_gc_free, call_info);
    }
    return call_info->object;
}

static VALUE prof_aggregate_call_info_allocate(VALUE klass)
{
    prof_call_info_t* call_info = prof_call_info_create(NULL, NULL, Qnil, 0);
    call_info->object = prof_aggregate_call_info_wrap(call_info);
    return call_info->object;
}

void rp_init_aggregate_call_info()
{
    // AggregateCallInfo
    cRpAggregateCallInfo = rb_define_class_under(mProf, "AggregateCallInfo", cRpCallnfo);
   // rb_undef_method(CLASS_OF(cRpAggregateCallInfo), "new");
   // rb_define_alloc_func(cRpAggregateCallInfo, prof_aggregate_call_info_allocate);
}
