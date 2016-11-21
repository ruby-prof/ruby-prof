/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_MEASUREMENT_H__
#define __RP_MEASUREMENT_H__

extern VALUE mMeasure;

typedef struct
{
    size_t len;
    double values[];
} prof_measurements_t;

typedef double (*get_measurement)();

typedef enum
{
    MEASURE_WALL_TIME,
    MEASURE_PROCESS_TIME,
    MEASURE_CPU_TIME,
    MEASURE_ALLOCATIONS,
    MEASURE_MEMORY,
    MEASURE_GC_TIME,
    MEASURE_GC_RUNS,
} prof_measure_mode_t;

typedef struct
{
    size_t len;
    prof_measure_mode_t* measure_modes;
    get_measurement measures[];
} prof_measurer_t;


prof_measurer_t* prof_get_measurer(prof_measure_mode_t* measures, size_t len);
get_measurement prof_measurer_allocations();
get_measurement prof_measurer_cpu_time();
get_measurement prof_measurer_gc_runs();
get_measurement prof_measurer_gc_time();
get_measurement prof_measurer_memory();
get_measurement prof_measurer_process_time();
get_measurement prof_measurer_wall_time();

void prof_measurer_take_measurements(prof_measurer_t* measurer, prof_measurements_t* dest);

void rp_init_measure();
void rp_init_measure_allocations();
void rp_init_measure_cpu_time();
void rp_init_measure_gc_runs();
void rp_init_measure_gc_time();
void rp_init_measure_memory();
void rp_init_measure_process_time();
void rp_init_measure_wall_time();

#endif //__RP_MEASUREMENT_H__
