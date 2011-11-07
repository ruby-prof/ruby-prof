/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"
#include <time.h>

static VALUE cMeasureProcessTime;

static double
measure_process_time()
{
    double time;
#if defined(__linux__)
    struct timespec clock;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID , &clock);
    time = clock.tv_sec * 1000000000 + clock.tv_nsec ;
#else
    time = clock();
#endif

#if defined(__linux__)
    return (double) time / 1000000000;
#else
    return (double) time / CLOCKS_PER_SEC;
#endif
}

/* call-seq:
   measure_process_time -> float

Returns the process time.*/
static VALUE
prof_measure_process_time(VALUE self)
{
    return rb_float_new(measure_process_time());
}

prof_measurer_t* prof_measurer_process_time()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_process_time;
  return measure;
}


void rp_init_measure_process_time()
{
    rb_define_const(mProf, "CLOCKS_PER_SEC", INT2NUM(CLOCKS_PER_SEC));
    rb_define_const(mProf, "PROCESS_TIME", INT2NUM(MEASURE_PROCESS_TIME));

    cMeasureProcessTime = rb_define_class_under(mMeasure, "ProcessTime", rb_cObject);
    rb_define_singleton_method(cMeasureProcessTime, "measure", prof_measure_process_time, 0);
}
