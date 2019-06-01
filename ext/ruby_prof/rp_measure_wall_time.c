/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */
#include "ruby_prof.h"
/*#if HAVE_GETTIMEOFDAY && !defined(_WIN32)
#include <sys/time.h>
#endif*/

static VALUE cMeasureWallTime;

static double
measure_wall_time()
{
    double current_time;

#if defined(_WIN32)
    current_time = GetTickCount() / 1000.0;
#elif defined(__linux__)
    struct timespec tv;
    clock_gettime(CLOCK_MONOTONIC, &tv);
    return tv.tv_sec + (tv.tv_nsec / 1000000000.0);
#elif defined(__APPLE__)
    // #pragma message "GetRealTime: mach_absolute_time"
    // Mac OS X
    // https://developer.apple.com/library/mac/qa/qa1398/_index.html
    current_time = mach_absolute_time() * mach_timebase.numer / mach_timebase.denom / 1000;
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
}
