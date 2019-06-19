/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "rp_measure.h"

static VALUE cMeasureAllocations;
VALUE total_allocated_objects_key;

static double
measure_allocations(rb_trace_arg_t* trace_arg)
{
    return rb_gc_stat(total_allocated_objects_key);
}

prof_measurer_t* prof_measurer_allocations()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_allocations;
  measure->multiplier = 1;
  return measure;
}

void rp_init_measure_allocations()
{
    total_allocated_objects_key = ID2SYM(rb_intern("total_allocated_objects"));
    rb_define_const(mProf, "ALLOCATIONS", INT2NUM(MEASURE_ALLOCATIONS));

    cMeasureAllocations = rb_define_class_under(mMeasure, "Allocations", rb_cObject);
}
