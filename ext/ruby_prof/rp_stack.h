/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_STACK__
#define __RP_STACK__

#include <ruby.h>

#include "rp_measure.h"
#include "rp_call_info.h"


typedef struct
{
    double start;
    double switch_t; // Time at switch to different thread
    double wait;
    double child;
    double pause; //Time pause() was initiated
    double dead; // Time to ignore (i.e. total amount of time between pause/resume blocks)
} prof_frame_measurement_t;

/* Temporary object that maintains profiling information
   for active methods.  They are created and destroyed
   as the program moves up and down its stack. */
typedef struct
{
    /* Caching prof_method_t values significantly
       increases performance. */
    prof_call_info_t *call_info;

    unsigned int line;
    unsigned int passes; /* Count of "pass" frames, _after_ this one. */

    size_t measurements_len;
    prof_frame_measurement_t measurements[];
} prof_frame_t;

#define prof_frame_is_real(f) ((f)->passes == 0)
#define prof_frame_is_pass(f) ((f)->passes > 0)

#define prof_frame_is_paused(f) (f->measurements[0].pause >= 0)
#define prof_frame_is_unpaused(f) (f->measurements[0].pause < 0)

void prof_frame_pause(prof_frame_t*, prof_measurements_t *current_measurements);
void prof_frame_unpause(prof_frame_t*, prof_measurements_t *current_measurements);

/* Current stack of active methods.*/
typedef struct prof_stack_t
{
    size_t measurements_len;
    prof_frame_t *start;
    prof_frame_t *end;
    prof_frame_t *ptr;
} prof_stack_t;

prof_stack_t *prof_stack_create(size_t measurements_len);
void prof_stack_free(prof_stack_t *stack);

prof_frame_t *prof_stack_push(prof_stack_t *stack, prof_call_info_t *call_info,
                              prof_measurements_t *measurements, int paused);
prof_frame_t *prof_stack_pop(prof_stack_t *stack, prof_measurements_t *measurements);
prof_frame_t *prof_stack_pass(prof_stack_t *stack);

#define FRAME_SIZE(measurements_len) (sizeof(prof_frame_t) + (measurements_len) * sizeof(prof_frame_measurement_t))
#define NEXT_FRAME(stack) (prof_frame_t*) \
    ((uintptr_t)((stack)->ptr) + FRAME_SIZE((stack)->measurements_len))
#define PREVIOUS_FRAME(stack) (prof_frame_t*) \
    ((uintptr_t)((stack)->ptr) - FRAME_SIZE((stack)->measurements_len))

static inline prof_frame_t *
prof_stack_peek(prof_stack_t *stack) {
    if (stack->ptr != stack->start) {
        return (prof_frame_t*) ((uintptr_t)(stack->ptr) - 1 * FRAME_SIZE(stack->measurements_len));
    } else {
        return NULL;
    }
}


#endif //__RP_STACK__
