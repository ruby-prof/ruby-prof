/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_MEASURE_PROCESS_TIME_H__
#define __RP_MEASURE_PROCESS_TIME_H__

#include <time.h>

#define MEASURE_PROCESS_TIME 0

static prof_measure_t
measure_process_time()
{
#if defined(__linux__)
    struct timespec time;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID , &time);
    return time.tv_sec * 1000000000 + time.tv_nsec ;
#else
    return clock();
#endif
}


static double
convert_process_time(prof_measure_t c)
{
#if defined(__linux__)
    return (double) c / 1000000000;
#else
    return (double) c / CLOCKS_PER_SEC;
#endif
}

/* Document-method: measure_process_time
   call-seq:
     measure_process_time -> float

Returns the process time.*/
static VALUE
prof_measure_process_time(VALUE self)
{
    return rb_float_new(convert_process_time(measure_process_time()));
}

#endif //__RP_MEASURE_PROCESS_TIME_H__