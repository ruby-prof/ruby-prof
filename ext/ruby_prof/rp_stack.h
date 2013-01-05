/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_STACK__
#define __RP_STACK__

#include <ruby.h>

#include "rp_measure.h"
#include "rp_call_info.h"


/* Temporary object that maintains profiling information
   for active methods.  They are created and destroyed
   as the program moves up and down its stack. */
typedef struct 
{
    /* Caching prof_method_t values significantly
       increases performance. */
    prof_call_info_t *call_info;
    double start_time;
    double switch_time;  /* Time at switch to different thread */
    double wait_time;
    double child_time;
    int depth;
    unsigned int line;
} prof_frame_t;

/* Current stack of active methods.*/
typedef struct 
{
    prof_frame_t *start;
    prof_frame_t *end;
    prof_frame_t *ptr;
} prof_stack_t;

prof_stack_t * prof_stack_create();
void prof_stack_free(prof_stack_t *stack);
prof_frame_t * prof_stack_push(prof_stack_t *stack, double measurement);
prof_frame_t * prof_stack_pop(prof_stack_t *stack, double measurement);
prof_frame_t * prof_stack_peek(prof_stack_t *stack);

#endif //__RP_STACK__
