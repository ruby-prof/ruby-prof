/* :nodoc: 
 * Copyright (C) 2008  Shugo Maeda <shugo@ruby-lang.org>
 *                     Charlie Savage <cfis@savagexi.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE. */

#include <ruby.h>

#if defined(_WIN32) || (defined(__GNUC__) && (defined(__i386__) || defined(__x86_64__) || defined(__powerpc__) || defined(__ppc__)))
#define MEASURE_CPU_TIME 2

static unsigned long long cpu_frequency;

#if defined(__GNUC__)

#include <stdint.h>

static prof_measure_t
measure_cpu_time()
{
#if defined(__i386__) || defined(__x86_64__) 
    uint32_t a, d;
    __asm__ volatile("rdtsc" : "=a" (a), "=d" (d));
    return ((uint64_t)d << 32) + a;
#elif defined(__powerpc__) || defined(__ppc__)
    unsigned long long x, y;

    __asm__ __volatile__ ("\n\
1:	mftbu   %1\n\
  mftb    %L0\n\
  mftbu   %0\n\
  cmpw    %0,%1\n\
  bne-    1b"
  : "=r" (x), "=r" (y));
    return x;
#endif
}

#elif defined(_WIN32)

static prof_measure_t
measure_cpu_time()
{
    prof_measure_t cycles = 0;

    __asm
    {
        rdtsc
        mov DWORD PTR cycles, eax
        mov DWORD PTR [cycles + 4], edx
    }
    return cycles;
}

#endif


/* The _WIN32 check is needed for msys (and maybe cygwin?) */
#if defined(__GNUC__) && !defined(_WIN32)

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

unsigned long long get_cpu_frequency()
{
    unsigned long long x, y;
    unsigned long long frequency;
    x = measure_cpu_time();

    /* Use the windows sleep function, not Ruby's */
    Sleep(500);
    y = measure_cpu_time();
    frequency = 2*(y-x);
    return frequency;
}
#endif

static double
convert_cpu_time(prof_measure_t c)
{
    return (double) c / cpu_frequency;
}

/* Document-method: prof_measure_cpu_time
   call-seq:
     measure_cpu_time -> float

Returns the cpu time.*/
static VALUE
prof_measure_cpu_time(VALUE self)
{
    return rb_float_new(convert_cpu_time(measure_cpu_time()));
}

/* Document-method: prof_get_cpu_frequency
   call-seq:
     cpu_frequency -> int

Returns the cpu's frequency.  This value is needed when 
RubyProf::measure_mode is set to CPU_TIME. */
static VALUE
prof_get_cpu_frequency(VALUE self)
{
    return ULL2NUM(cpu_frequency);
}

/* Document-method: prof_set_cpu_frequency
   call-seq:
     cpu_frequency=value -> void

Sets the cpu's frequency.   This value is needed when 
RubyProf::measure_mode is set to CPU_TIME. */
static VALUE
prof_set_cpu_frequency(VALUE self, VALUE val)
{
    cpu_frequency = NUM2LL(val);
    return val;
}

#endif
