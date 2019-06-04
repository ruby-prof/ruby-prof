/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

VALUE mMeasure;

prof_measurer_t* prof_measurer_allocations(void);
prof_measurer_t* prof_measurer_cpu_time(void);
prof_measurer_t* prof_measurer_gc_runs(void);
prof_measurer_t* prof_measurer_gc_time(void);
prof_measurer_t* prof_measurer_memory(void);
prof_measurer_t* prof_measurer_process_time(void);
prof_measurer_t* prof_measurer_wall_time(void);

void rp_init_measure_allocations(void);
void rp_init_measure_cpu_time(void);
void rp_init_measure_gc_runs(void);
void rp_init_measure_gc_time(void);
void rp_init_measure_memory(void);
void rp_init_measure_process_time(void);
void rp_init_measure_wall_time(void);

prof_measurer_t* prof_get_measurer(prof_measure_mode_t measure)
{
    switch (measure) {
    case MEASURE_WALL_TIME:
        return prof_measurer_wall_time();
    case MEASURE_PROCESS_TIME:
        return prof_measurer_process_time();
    case MEASURE_CPU_TIME:
        return prof_measurer_cpu_time();
    case MEASURE_ALLOCATIONS:
        return prof_measurer_allocations();
    case MEASURE_MEMORY:
        return prof_measurer_memory();
    case MEASURE_GC_TIME:
        return prof_measurer_gc_time();
    case MEASURE_GC_RUNS:
        return prof_measurer_gc_runs();
    default:
        rb_raise(rb_eArgError, "Unknown measure mode: %d", measure);
    }
};

double prof_measure(prof_measurer_t* measurer)
{
    double measurement = measurer->measure();
    return measurement * measurer->multiplier;
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
