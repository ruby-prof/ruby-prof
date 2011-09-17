/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "ruby_prof.h"

static VALUE cMeasureMemory;

#if defined(HAVE_RB_GC_ALLOCATED_SIZE)
#define TOGGLE_GC_STATS 1

static double
measure_memory()
{
#if defined(HAVE_LONG_LONG)
    return NUM2LL(rb_gc_allocated_size() / 1024);
#else
    return NUM2ULONG(rb_gc_allocated_size() / 1024);
#endif
}

#elif defined(HAVE_RB_GC_MALLOC_ALLOCATED_SIZE)

static double
measure_memory()
{
    return rb_gc_malloc_allocated_size() / 1024;
}


#elif defined(HAVE_RB_HEAP_TOTAL_MEM)

static double
measure_memory()
{
    return rb_heap_total_mem() / 1024;
}

#else

static double
measure_memory()
{
    return 0;
}

#endif

prof_measurer_t* prof_measurer_memory()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_memory;
  return measure;
}

/* call-seq:
   measure_process_time -> float

Returns the process time.*/
static VALUE
prof_measure_memory(VALUE self)
{
    return rb_float_new(measure_memory());
}

void rp_init_measure_memory()
{
    rb_define_const(mProf, "MEMORY", INT2NUM(MEASURE_MEMORY));

    cMeasureMemory = rb_define_class_under(mMeasure, "Memory", rb_cObject);
    rb_define_singleton_method(cMeasureMemory, "measure", prof_measure_memory, 0);
}
