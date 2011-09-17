/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

static VALUE cMeasureCpuTime;

static unsigned LONG_LONG cpu_frequency = 0;

/* The _WIN32 check is needed for msys (and maybe cygwin?) */
#if defined(__GNUC__) && !defined(_WIN32)

#include <stdint.h>

static double
measure_cpu_time()
{
    unsigned long long time;
#if defined(__i386__) || defined(__x86_64__)
    uint32_t a, d;
    __asm__ volatile("rdtsc" : "=a" (a), "=d" (d));
    time = ((uint64_t)d << 32) + a;
#elif defined(__powerpc__) || defined(__ppc__)
    unsigned long long x, y;

    __asm__ __volatile__ ("\n\
1:      mftbu   %1\n\
  mftb    %L0\n\
  mftbu   %0\n\
  cmpw    %0,%1\n\
  bne-    1b"
  : "=r" (x), "=r" (y));
    time = x;
#endif
    return time / cpu_frequency;
}

unsigned long long get_cpu_frequency()
{
    unsigned long long x, y;

    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 500000000;
    x = measure_cpu_time();
    nanosleep(&ts, NULL);
    y = measure_cpu_time();
    return (y - x) * 2;
}

#elif defined(_WIN32)

static double
measure_cpu_time()
{
    double cycles = 0;

    __asm
    {
        rdtsc
        mov DWORD PTR cycles, eax
        mov DWORD PTR [cycles + 4], edx
    }
    return cycles / cpu_frequency;
}

unsigned LONG_LONG get_cpu_frequency()
{
    unsigned LONG_LONG x, y;
    unsigned LONG_LONG frequency;
    x = measure_cpu_time();

    /* Use the windows sleep function, not Ruby's */
    Sleep(500);
    y = measure_cpu_time();
    frequency = 2*(y-x);
    return frequency;
}
#endif

static double
convert_cpu_time(double c)
{
    return (double) c / cpu_frequency;
}


prof_measurer_t* prof_measurer_cpu_time()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_cpu_time;
  return measure;
}

/* call-seq:
   measure -> float

Returns the cpu time.*/
static VALUE
prof_measure_cpu_time(VALUE self)
{
    return rb_float_new(measure_cpu_time());
}

/* call-seq:
   cpu_frequency -> int

Returns the cpu's frequency.  This value is needed when
RubyProf::measure_mode is set to CPU_TIME. */
static VALUE
prof_get_cpu_frequency(VALUE self)
{
    return ULL2NUM(cpu_frequency);
}

/* call-seq:
   cpu_frequency=value -> void

Sets the cpu's frequency.   This value is needed when
RubyProf::measure_mode is set to CPU_TIME. */
static VALUE
prof_set_cpu_frequency(VALUE self, VALUE val)
{
    cpu_frequency = NUM2LL(val);
    return val;
}

void rp_init_measure_cpu_time()
{
    rb_define_const(mProf, "CPU_TIME", INT2NUM(MEASURE_CPU_TIME));

    cMeasureCpuTime = rb_define_class_under(mMeasure, "CpuTime", rb_cObject);
    rb_define_singleton_method(cMeasureCpuTime, "measure", prof_measure_cpu_time, 0);
    rb_define_singleton_method(cMeasureCpuTime, "frequency", prof_get_cpu_frequency, 0);
    rb_define_singleton_method(cMeasureCpuTime, "frequency=", prof_set_cpu_frequency, 1);

    /* Get cpu_frequency */
    cpu_frequency = get_cpu_frequency();
}
