/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_MEASUREMENT_H__
#define __RP_MEASUREMENT_H__

#ifdef HAVE_LONG_LONG
typedef unsigned LONG_LONG prof_measure_t; // long long is 8 bytes on 32-bit
#else
typedef unsigned long prof_measure_t;
#endif

int measure_mode;
prof_measure_t (*get_measurement)();
double (*convert_measurement)(prof_measure_t);


#endif //__RP_MEASUREMENT_H__
