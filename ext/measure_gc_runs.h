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

#if defined(HAVE_RB_GC_COLLECTIONS)
#define MEASURE_GC_RUNS 5

static prof_measure_t
measure_gc_runs()
{
    return NUM2INT(rb_gc_collections());
}

static double
convert_gc_runs(prof_measure_t c)
{
    return c;
}

/* Document-method: prof_measure_gc_runs
   call-seq:
     gc_runs -> Integer

Returns the total number of garbage collections.*/
static VALUE
prof_measure_gc_runs(VALUE self)
{
    return rb_gc_collections();
}

#elif defined(HAVE_RB_GC_HEAP_INFO)
#define MEASURE_GC_RUNS 5

static prof_measure_t
measure_gc_runs()
{
  VALUE h = rb_gc_heap_info();
  return NUM2UINT(rb_hash_aref(h, rb_str_new2("num_gc_passes")));
}

static double
convert_gc_runs(prof_measure_t c)
{
    return c;
}

static VALUE
prof_measure_gc_runs(VALUE self)
{
  VALUE h = rb_gc_heap_info();
  return rb_hash_aref(h, rb_str_new2("num_gc_passes"));
}

#endif
