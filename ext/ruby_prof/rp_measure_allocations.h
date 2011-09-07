/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#ifndef __RP_MEASURE_ALLOCATIONS_H__
#define __RP_MEASURE_ALLOCATIONS_H__

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

#endif //__RP_MEASURE_ALLOCATIONS_H__