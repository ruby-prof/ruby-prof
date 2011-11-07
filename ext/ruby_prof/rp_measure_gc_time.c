/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "ruby_prof.h"

static VALUE cMeasureGcTimes;

#if defined(HAVE_RB_GC_TIME)

static double
measure_gc_time()
{
    int conversion = 1000000
#if HAVE_LONG_LONG
    return NUM2LL(rb_gc_time() / conversion);
#else
    return NUM2LONG(rb_gc_time() / conversion));
#endif
}

/* call-seq:
   gc_time -> Integer

Returns the time spent doing garbage collections in microseconds.*/
static VALUE
prof_measure_gc_time(VALUE self)
{
    return rb_gc_time();
}

#else

static double
measure_gc_time()
{
    return 0;
}
#endif

prof_measurer_t* prof_measurer_gc_time()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_gc_time;
  return measure;
}

/* call-seq:
   measure -> float

Returns the number of GC runs.*/
static VALUE
prof_measure_gc_time(VALUE self)
{
#if defined(HAVE_LONG_LONG)
    return ULL2NUM(measure_gc_time());
#else
    return ULONG2NUM(measure_gc_time());
#endif
}
void rp_init_measure_gc_time()
{
    rb_define_const(mProf, "GC_TIME", INT2NUM(MEASURE_GC_TIME));

    cMeasureGcTimes = rb_define_class_under(mMeasure, "GcTime", rb_cObject);
    rb_define_singleton_method(cMeasureGcTimes, "measure", prof_measure_gc_time, 0);
}
