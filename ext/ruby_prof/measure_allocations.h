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

#if defined(HAVE_RB_OS_ALLOCATED_OBJECTS)
#define MEASURE_ALLOCATIONS 3

static prof_measure_t
measure_allocations()
{
    return rb_os_allocated_objects();
}

static double
convert_allocations(prof_measure_t c)
{
    return  c;
}

/* Document-method: prof_measure_allocations
   call-seq:
     measure_allocations -> int

Returns the total number of object allocations since Ruby started.*/
static VALUE
prof_measure_allocations(VALUE self)
{
#if defined(HAVE_LONG_LONG)
    return ULL2NUM(rb_os_allocated_objects());
#else
    return ULONG2NUM(rb_os_allocated_objects());
#endif
}

#elif defined(HAVE_RB_GC_MALLOC_ALLOCATIONS)
#define MEASURE_ALLOCATIONS 3

static prof_measure_t
measure_allocations()
{
    return rb_gc_malloc_allocations();
}

static double
convert_allocations(prof_measure_t c)
{
    return c;
}

static VALUE
prof_measure_allocations(VALUE self)
{
#if defined(HAVE_LONG_LONG)
    return ULL2NUM(rb_os_allocated_objects());
#else
    return ULONG2NUM(rb_os_allocated_objects());
#endif
}
#endif
