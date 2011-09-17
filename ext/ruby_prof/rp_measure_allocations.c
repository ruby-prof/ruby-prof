/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "ruby_prof.h"

static VALUE cMeasureAllocations;

#if defined(HAVE_RB_OS_ALLOCATED_OBJECTS)

static double
measure_allocations()
{
    return rb_os_allocated_objects();
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

static double
measure_allocations()
{
    return rb_gc_malloc_allocations();
}

#else

static double
measure_allocations()
{
    return 0;
}

#endif


prof_measurer_t* prof_measurer_allocations()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_allocations;
  return measure;
}

/* call-seq:
     measure -> int

Returns the number of Ruby object allocations. */

static VALUE
prof_measure_allocations(VALUE self)
{
#if defined(HAVE_LONG_LONG)
    return ULL2NUM(measure_allocations());
#else
    return ULONG2NUM(measure_allocations());
#endif
}

void rp_init_measure_allocations()
{
    rb_define_const(mProf, "ALLOCATIONS", INT2NUM(MEASURE_ALLOCATIONS));

    cMeasureAllocations = rb_define_class_under(mMeasure, "Allocations", rb_cObject);
    rb_define_singleton_method(cMeasureAllocations, "measure", prof_measure_allocations, 0);    
}
