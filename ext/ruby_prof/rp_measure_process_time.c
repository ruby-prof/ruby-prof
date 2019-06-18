/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_measure.h"
#include <time.h>

static VALUE cMeasureProcessTime;

static double
measure_process_time(void)
{
#if defined(_WIN32)
    FILETIME  createTime;
    FILETIME  exitTime;
    FILETIME  sysTime;
    FILETIME  userTime;

	ULARGE_INTEGER sysTimeInt;
	ULARGE_INTEGER userTimeInt;

	GetProcessTimes(GetCurrentProcess(), &createTime, &exitTime, &sysTime, &userTime); 

	sysTimeInt.LowPart = sysTime.dwLowDateTime;
	sysTimeInt.HighPart = sysTime.dwHighDateTime;
    userTimeInt.LowPart = userTime.dwLowDateTime;
    userTimeInt.HighPart = userTime.dwHighDateTime;

	return sysTimeInt.QuadPart + userTimeInt.QuadPart;
#else
    struct timespec clock;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID , &clock);
    return clock.tv_sec + (clock.tv_nsec/1000000000.0);
#endif
}

static double
multiplier_process_time(void)
{
#if defined(_WIN32)
    // Times are in 100-nanosecond time units.  So instead of 10-9 use 10-7
    return 1.0 / 10000000.0;
#else
    return 1.0;
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
  measure->multiplier = multiplier_process_time();
  return measure;
}

void rp_init_measure_process_time()
{
    rb_define_const(mProf, "CLOCKS_PER_SEC", INT2NUM(CLOCKS_PER_SEC));
    rb_define_const(mProf, "PROCESS_TIME", INT2NUM(MEASURE_PROCESS_TIME));

    cMeasureProcessTime = rb_define_class_under(mMeasure, "ProcessTime", rb_cObject);
    rb_define_singleton_method(cMeasureProcessTime, "measure", prof_measure_process_time, 0);
}
