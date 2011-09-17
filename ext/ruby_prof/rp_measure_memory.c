/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "ruby_prof.h"

static VALUE cMeasureMemory;

#if defined(HAVE_RB_GC_ALLOCATED_SIZE)
#define TOGGLE_GC_STATS 1

static prof_measurement_t
measure_memory()
{
#if defined(HAVE_LONG_LONG)
    return NUM2LL(rb_gc_allocated_size());
#else
    return NUM2ULONG(rb_gc_allocated_size());
#endif
}

static double
convert_memory(prof_measurement_t c)
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

static prof_measurement_t
measure_memory()
{
    return rb_gc_malloc_allocated_size();
}

static double
convert_memory(prof_measurement_t c)
{
    return (double) c / 1024;
}

static VALUE
prof_measure_memory(VALUE self)
{
    return UINT2NUM(rb_gc_malloc_allocated_size());
}

#elif defined(HAVE_RB_HEAP_TOTAL_MEM)

static prof_measurement_t
measure_memory()
{
    return rb_heap_total_mem();
}

static double
convert_memory(prof_measurement_t c)
{
    return (double) c / 1024;
}

static VALUE
prof_measure_memory(VALUE self)
{
    return ULONG2NUM(rb_heap_total_mem());
}

#else

static prof_measurement_t
measure_memory()
{
    return 0;
}

static double
convert_memory(prof_measurement_t c)
{
    return c;
}

#endif

prof_measurer_t* prof_measurer_memory()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_memory;
  measure->convert = convert_memory;
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
