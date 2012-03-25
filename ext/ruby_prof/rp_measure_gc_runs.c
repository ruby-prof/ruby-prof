/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "ruby_prof.h"

static VALUE cMeasureGcRuns;

#if defined(HAVE_RB_GC_COLLECTIONS)

#define MEASURE_GC_RUNS_ENABLED Qtrue

static double
measure_gc_runs()
{
    return NUM2INT(rb_gc_collections());
}

/* call-seq:
   gc_runs -> Integer

Returns the total number of garbage collections.*/
static VALUE
prof_measure_gc_runs(VALUE self)
{
    return rb_gc_collections();
}

#elif defined(HAVE_RB_GC_HEAP_INFO)

#define MEASURE_GC_RUNS_ENABLED Qtrue

static double
measure_gc_runs()
{
  VALUE h = rb_gc_heap_info();
  return NUM2UINT(rb_hash_aref(h, rb_str_new2("num_gc_passes")));
}

static VALUE
prof_measure_gc_runs(VALUE self)
{
  VALUE h = rb_gc_heap_info();
  return rb_hash_aref(h, rb_str_new2("num_gc_passes"));
}

#else 

#define MEASURE_GC_RUNS_ENABLED Qfalse

static double
measure_gc_runs()
{
  return 0;
}
#endif

prof_measurer_t* prof_measurer_gc_runs()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_gc_runs;
  return measure;
}

/* call-seq:
   measure -> int

Returns the number of GC runs.*/
static VALUE
prof_measure_gc_runs(VALUE self)
{
#if defined(HAVE_LONG_LONG)
    return ULL2NUM(measure_gc_runs());
#else
    return ULONG2NUM(measure_gc_runs());
#endif
}

void rp_init_measure_gc_runs()
{
    rb_define_const(mProf, "GC_RUNS", INT2NUM(MEASURE_GC_RUNS));
    rb_define_const(mProf, "GC_RUNS_ENABLED", MEASURE_GC_RUNS_ENABLED);
    
    cMeasureGcRuns = rb_define_class_under(mMeasure, "GcRuns", rb_cObject);
    rb_define_singleton_method(cMeasureGcRuns, "measure", prof_measure_gc_runs, 0);
}