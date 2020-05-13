/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "rp_measurement.h"

static VALUE cMeasureAllocations;
VALUE total_allocated_objects_key;

static double measure_allocations_via_gc_stats(rb_trace_arg_t* trace_arg)
{
    return (double)rb_gc_stat(total_allocated_objects_key);
}

static double measure_allocations_via_tracing(rb_trace_arg_t* trace_arg)
{
    static double result = 0;

    if (trace_arg)
    {
        rb_event_flag_t event = rb_tracearg_event_flag(trace_arg);
        if (event == RUBY_INTERNAL_EVENT_NEWOBJ)
            result++;
    }
    return result;
}

prof_measurer_t* prof_measurer_allocations(bool track_allocations)
{
    prof_measurer_t* measure = ALLOC(prof_measurer_t);
    measure->mode = MEASURE_ALLOCATIONS;
    measure->multiplier = 1;
    measure->track_allocations = track_allocations;

    if (track_allocations)
        measure->measure = measure_allocations_via_tracing;
    else
        measure->measure = measure_allocations_via_gc_stats;

    return measure;
}

void rp_init_measure_allocations()
{
    total_allocated_objects_key = ID2SYM(rb_intern("total_allocated_objects"));
    rb_define_const(mProf, "ALLOCATIONS", INT2NUM(MEASURE_ALLOCATIONS));

    cMeasureAllocations = rb_define_class_under(mMeasure, "Allocations", rb_cObject);
}
