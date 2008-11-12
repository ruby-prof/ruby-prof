/* :nodoc: 
 * Copyright (C) 2008  Alexander Dymo <adymo@pluron.com>
 *
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


#if defined(HAVE_RB_GC_ALLOCATED_SIZE)
#define MEASURE_MEMORY 4
#define TOGGLE_GC_STATS 1
 
static prof_measure_t
measure_memory()
{
#if defined(HAVE_LONG_LONG)
    return NUM2LL(rb_gc_allocated_size());
#else
    return NUM2ULONG(rb_gc_allocated_size());
#endif
}

static double
convert_memory(prof_measure_t c)
{ 
    return (double) c / 1024; 
}

/* Document-method: prof_measure_memory
   call-seq:
     measure_memory -> int

Returns total allocated memory in bytes.*/
static VALUE
prof_measure_memory(VALUE self)
{
    return rb_gc_allocated_size();
}

#elif defined(HAVE_RB_GC_MALLOC_ALLOCATED_SIZE)
#define MEASURE_MEMORY 4

static prof_measure_t
measure_memory()
{
    return rb_gc_malloc_allocated_size();
}

static double
convert_memory(prof_measure_t c)
{
    return (double) c / 1024;
}

static VALUE
prof_measure_memory(VALUE self)
{
    return UINT2NUM(rb_gc_malloc_allocated_size());
}

#elif defined(HAVE_RB_HEAP_TOTAL_MEM)
#define MEASURE_MEMORY 4

static prof_measure_t
measure_memory()
{
    return rb_heap_total_mem();
}

static double
convert_memory(prof_measure_t c)
{
    return (double) c / 1024;
}

static VALUE
prof_measure_memory(VALUE self)
{
    return ULONG2NUM(rb_heap_total_mem());
}

#endif
