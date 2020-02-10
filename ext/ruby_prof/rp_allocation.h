/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef _RP_ALLOCATION_
#define _RP_ALLOCATION_

#include "ruby_prof.h"
#include "rp_method.h"

typedef struct prof_allocation_t
{
    st_data_t key;                    /* Key in hash table */
    unsigned int klass_flags;         /* Information about the type of class */
    VALUE klass;                      /* Klass that was created */
    VALUE klass_name;                 /* Name of the class that was created */
    VALUE source_file;                /* Line number where allocation happens */
    int source_line;                  /* Line number where allocation happens */
    int count;                        /* Number of allocations */
    size_t memory;                    /* Amount of allocated memory */
    VALUE object;                     /* Cache to wrapped object */
} prof_allocation_t;

void rp_init_allocation(void);
void prof_allocation_free(prof_allocation_t* allocation);
void prof_allocation_mark(void* data);
VALUE prof_allocation_wrap(prof_allocation_t* allocation);
prof_allocation_t* prof_allocation_get(VALUE self);
prof_allocation_t* prof_allocate_increment(prof_method_t* method, rb_trace_arg_t* trace_arg);


#endif //_RP_ALLOCATION_
