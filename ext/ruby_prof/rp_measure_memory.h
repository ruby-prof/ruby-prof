/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#ifndef __RP_MEASURE_GC_MEMORY_H__
#define __RP_MEASURE_GC_MEMORY_H__


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

#endif // __RP_MEASURE_GC_MEMORY_H__