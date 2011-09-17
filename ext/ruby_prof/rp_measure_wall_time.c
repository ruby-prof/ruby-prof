/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */
#include "ruby_prof.h"

static VALUE cMeasureWallTime;

static prof_measurement_t
measure_wall_time()
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000000 + tv.tv_usec;
}

static double
convert_wall_time(prof_measurement_t c)
{
    return (double) c / 1000000;
}

prof_measurer_t* prof_measurer_wall_time()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_wall_time;
  measure->convert = convert_wall_time;
  return measure;
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


void rp_init_measure_wall_time()
{
    rb_define_const(mProf, "WALL_TIME", INT2NUM(MEASURE_WALL_TIME));

    cMeasureWallTime = rb_define_class_under(mMeasure, "WallTime", rb_cObject);
    rb_define_singleton_method(cMeasureWallTime, "measure", prof_measure_wall_time, 0);
}
