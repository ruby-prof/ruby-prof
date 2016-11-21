/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

VALUE mMeasure;

prof_measurer_t*
prof_measurer_allocate(size_t len)
{
    prof_measurer_t* result =
      (prof_measurer_t*) ruby_xmalloc(
          sizeof(prof_measurer_t) + len * sizeof(get_measurement));
    result->len = len;
    return result;
}

prof_measurer_t* prof_get_measurer(prof_measure_mode_t* measures, size_t len)
{
    prof_measurer_t* measurer = prof_measurer_allocate(len);
    measurer->measure_modes = measures;

    for (size_t i = 0; i < len; i++) {
        switch (measures[i]) {
        case MEASURE_WALL_TIME:
            measurer->measures[i] = prof_measurer_wall_time();
            break;
        case MEASURE_PROCESS_TIME:
            measurer->measures[i] = prof_measurer_process_time();
            break;
        case MEASURE_CPU_TIME:
            measurer->measures[i] = prof_measurer_cpu_time();
            break;
        case MEASURE_ALLOCATIONS:
            measurer->measures[i] = prof_measurer_allocations();
            break;
        case MEASURE_MEMORY:
            measurer->measures[i] = prof_measurer_memory();
            break;
        case MEASURE_GC_TIME:
            measurer->measures[i] = prof_measurer_gc_time();
            break;
        case MEASURE_GC_RUNS:
            measurer->measures[i] = prof_measurer_gc_runs();
            break;
        default:
            rb_raise(rb_eArgError, "Unknown measure mode: %d", measures[i]);
        }
    }

    return measurer;
};

void prof_measurer_take_measurements(prof_measurer_t* measurer, prof_measurements_t* dest)
{
    for (size_t i = 0; i < measurer->len; i++) {
        dest->values[i] = measurer->measures[i]();
    }
}

void rp_init_measure()
{
    mMeasure = rb_define_module_under(mProf, "Measure");
    rp_init_measure_wall_time();
    rp_init_measure_cpu_time();
    rp_init_measure_process_time();
    rp_init_measure_allocations();
    rp_init_measure_memory();
    rp_init_measure_gc_time();
    rp_init_measure_gc_runs();
}
