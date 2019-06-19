/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_MEASUREMENT_H__
#define __RP_MEASUREMENT_H__

#include "ruby_prof.h"

extern VALUE mMeasure;

typedef double (*get_measurement)(rb_trace_arg_t *trace_arg);

typedef struct
{
    get_measurement measure;
    double multiplier;
} prof_measurer_t;

typedef enum
{
    MEASURE_WALL_TIME,
    MEASURE_PROCESS_TIME,
    MEASURE_ALLOCATIONS,
} prof_measure_mode_t;

/* Callers and callee information for a method. */
typedef struct prof_measurement_t
{
    double total_time;
    double self_time;
    double wait_time;
    int called;
    VALUE object;
} prof_measurement_t;

prof_measurer_t* prof_get_measurer(prof_measure_mode_t measure);
double prof_measure(prof_measurer_t *measurer, rb_trace_arg_t* trace_arg);

prof_measurement_t *prof_measurement_create(void);
VALUE prof_measurement_wrap(prof_measurement_t *measurement);
prof_measurement_t* prof_get_measurement(VALUE self);
void prof_measurement_mark(void *data);

void rp_init_measure(void);

#endif //__RP_MEASUREMENT_H__
