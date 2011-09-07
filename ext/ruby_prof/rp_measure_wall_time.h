/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */
#ifndef __RP_MEASURE_WALL_TIME_H__
#define __RP_MEASURE_WALL_TIME_H__


#define MEASURE_WALL_TIME 1

static prof_measure_t
measure_wall_time()
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000000 + tv.tv_usec;
}

static double
convert_wall_time(prof_measure_t c)
{
    return (double) c / 1000000;
}

/* Document-method: prof_measure_wall_time
   call-seq:
     measure_wall_time -> float

Returns the wall time.*/
static VALUE
prof_measure_wall_time(VALUE self)
{
    return rb_float_new(convert_wall_time(measure_wall_time()));
}

#endif //__RP_MEASURE_WALL_TIME_H__