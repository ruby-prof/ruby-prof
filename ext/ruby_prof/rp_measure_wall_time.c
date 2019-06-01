/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */
#include "ruby_prof.h"

#if defined(__APPLE__)
#include <mach/mach_time.h>
mach_timebase_info_data_t mach_timebase;
#elif !defined(_WIN32)
#include <sys/time.h>
#endif

static VALUE cMeasureWallTime;

static uint64_t
measure_wall_time()
{
#if defined(_WIN32)
    return GetTickCount() / 1000;
#elif defined(__linux__)
    struct timespec tv;
    clock_gettime(CLOCK_MONOTONIC, &tv);
    return tv.tv_sec + (tv.tv_nsec / 1000000000.0);
#elif defined(__APPLE__)
    return mach_absolute_time();// * (uint64_t)mach_timebase.numer / (uint64_t)mach_timebase.denom;
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + (tv.tv_usec / 1000000.0); 
#endif
}

prof_measurer_t* prof_measurer_wall_time()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_wall_time;
  return measure;
}

/* Document-method: prof_measure_wall_time
   call-seq:
     measure_wall_time -> float

Returns the wall time.*/
static VALUE
prof_measure_wall_time(VALUE self)
{
    return rb_float_new(measure_wall_time());
}

void rp_init_measure_wall_time()
{
    rb_define_const(mProf, "WALL_TIME", INT2NUM(MEASURE_WALL_TIME));
    rb_define_const(mProf, "WALL_TIME_ENABLED", Qtrue);

    cMeasureWallTime = rb_define_class_under(mMeasure, "WallTime", rb_cObject);
    rb_define_singleton_method(cMeasureWallTime, "measure", prof_measure_wall_time, 0);

    mach_timebase_info(&mach_timebase);
}
