/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* :nodoc: */

#include "ruby_prof.h"

static VALUE cMeasureMemory;
VALUE heap_allocated_pages_key;

static double
measure_memory(void)
{
    return rb_gc_stat(heap_allocated_pages_key);
}

prof_measurer_t* prof_measurer_memory()
{
  prof_measurer_t* measure = ALLOC(prof_measurer_t);
  measure->measure = measure_memory;

  // Copied form gc.c
  /* default tiny heap size: 16KB */
  size_t HEAP_PAGE_ALIGN_LOG = 14;
  size_t HEAP_PAGE_ALIGN = (1UL << HEAP_PAGE_ALIGN_LOG);
  size_t HEAP_PAGE_ALIGN_MASK = (~(~0UL << HEAP_PAGE_ALIGN_LOG));
  size_t REQUIRED_SIZE_BY_MALLOC = (sizeof(size_t) * 5);
  size_t HEAP_PAGE_SIZE = (HEAP_PAGE_ALIGN - REQUIRED_SIZE_BY_MALLOC);
  measure->multiplier = HEAP_PAGE_SIZE;

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
    heap_allocated_pages_key = ID2SYM(rb_intern("heap_allocated_pages"));
    rb_define_const(mProf, "MEMORY", INT2NUM(MEASURE_MEMORY));

    cMeasureMemory = rb_define_class_under(mMeasure, "Memory", rb_cObject);
    rb_define_singleton_method(cMeasureMemory, "measure", prof_measure_memory, 0);
}
