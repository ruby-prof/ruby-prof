/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_MEASUREMENT_H__
#define __RP_MEASUREMENT_H__

extern VALUE mMeasure;

typedef double (*get_measurement)(void);

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
    MEASURE_MEMORY
} prof_measure_mode_t;

prof_measurer_t* prof_get_measurer(prof_measure_mode_t measure);
double prof_measure(prof_measurer_t *measurer);

void rp_init_measure(void);

#endif //__RP_MEASUREMENT_H__
