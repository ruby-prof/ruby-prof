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

#if defined(HAVE_RB_GC_TIME)
#define MEASURE_GC_TIME 6

static prof_measure_t
measure_gc_time()
{
#if HAVE_LONG_LONG
    return NUM2LL(rb_gc_time());
#else
    return NUM2LONG(rb_gc_time());
#endif
}

static double
convert_gc_time(prof_measure_t c)
{
    return (double) c / 1000000;
}

/* Document-method: prof_measure_gc_time
   call-seq:
     gc_time -> Integer

Returns the time spent doing garbage collections in microseconds.*/
static VALUE
prof_measure_gc_time(VALUE self)
{
    return rb_gc_time();
}

#endif
