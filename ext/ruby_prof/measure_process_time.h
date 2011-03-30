/*
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

#include <time.h>

#define MEASURE_PROCESS_TIME 0

static prof_measure_t
measure_process_time()
{
#if defined(__linux__)
    struct timespec time;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID , &time);
    return time.tv_sec * 1000000000 + time.tv_nsec ;
#else
    return clock();
#endif
}


static double
convert_process_time(prof_measure_t c)
{
#if defined(__linux__)
    return (double) c / 1000000000;
#else
    return (double) c / CLOCKS_PER_SEC;
#endif
}

/* Document-method: measure_process_time
   call-seq:
     measure_process_time -> float

Returns the process time.*/
static VALUE
prof_measure_process_time(VALUE self)
{
    return rb_float_new(convert_process_time(measure_process_time()));
}
