/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_stack.h"

#define INITIAL_STACK_SIZE 8

inline void
frame_pause(prof_frame_t *frame, double current_measurement)
{
    if (frame && frame_is_unpaused(frame))
        frame->pause_time = current_measurement;
}

inline void
frame_unpause(prof_frame_t *frame, double current_measurement)
{
    if (frame && frame_is_paused(frame)) {
        frame->dead_time += (current_measurement - frame->pause_time);
        frame->pause_time = -1;
    }
}


/* Creates a stack of prof_frame_t to keep track
   of timings for active methods. */
prof_stack_t *
stack_create()
{
    prof_stack_t *stack = ALLOC(prof_stack_t);
    stack->start = ALLOC_N(prof_frame_t, INITIAL_STACK_SIZE);
    stack->ptr = stack->start;
    stack->end = stack->start + INITIAL_STACK_SIZE;

    return stack;
}

void
stack_free(prof_stack_t *stack)
{
    xfree(stack->start);
    xfree(stack);
}

prof_frame_t *
stack_push(prof_stack_t *stack)
{
  prof_frame_t* result = NULL;

  /* Is there space on the stack?  If not, double
     its size. */
  if (stack->ptr == stack->end  )   
  {
    size_t len = stack->ptr - stack->start;
    size_t new_capacity = (stack->end - stack->start) * 2;
    REALLOC_N(stack->start, prof_frame_t, new_capacity);
    /* Memory just got moved, reset pointers */
    stack->ptr = stack->start + len;
    stack->end = stack->start + new_capacity;
  }

  // Setup returned stack pointer to be valid
  result = stack->ptr;
  result->child_time = 0;
  result->switch_time = 0;
  result->wait_time = 0;
  result->depth = (int)(stack->ptr - stack->start); // shortening of 64 bit into 32

  // Increment the stack ptr for next time
  stack->ptr++;

  // Return the result
  return result;
}

prof_frame_t *
stack_pop(prof_stack_t *stack)
{
    if (stack->ptr == stack->start)
      return NULL;
    else
      return --stack->ptr;
}

prof_frame_t *
stack_peek(prof_stack_t *stack)
{
    if (stack->ptr == stack->start)
      return NULL;
    else
      return stack->ptr - 1;
}
