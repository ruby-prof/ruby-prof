/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_stack.h"

#define INITIAL_STACK_SIZE 8

void
prof_frame_pause(prof_frame_t *frame, double current_measurement)
{
    if (frame && prof_frame_is_unpaused(frame))
        frame->pause_time = current_measurement;
}

void
prof_frame_unpause(prof_frame_t *frame, double current_measurement)
{
    if (frame && prof_frame_is_paused(frame)) {
        frame->dead_time += (current_measurement - frame->pause_time);
        frame->pause_time = -1;
    }
}


/* Creates a stack of prof_frame_t to keep track
   of timings for active methods. */
prof_stack_t *
prof_stack_create()
{
    prof_stack_t *stack = ALLOC(prof_stack_t);
    stack->start = ALLOC_N(prof_frame_t, INITIAL_STACK_SIZE);
    stack->ptr = stack->start;
    stack->end = stack->start + INITIAL_STACK_SIZE;

    return stack;
}

void
prof_stack_free(prof_stack_t *stack)
{
    xfree(stack->start);
    xfree(stack);
}

prof_frame_t *
prof_stack_push(prof_stack_t *stack, prof_call_info_t *call_info, double measurement, int paused)
{
  prof_frame_t *result;
  prof_frame_t* parent_frame;
  prof_method_t *method;

  /* Is there space on the stack?  If not, double
     its size. */
  if (stack->ptr == stack->end)
  {
    size_t len = stack->ptr - stack->start;
    size_t new_capacity = (stack->end - stack->start) * 2;
    REALLOC_N(stack->start, prof_frame_t, new_capacity);
    /* Memory just got moved, reset pointers */
    stack->ptr = stack->start + len;
    stack->end = stack->start + new_capacity;
  }

  parent_frame = prof_stack_peek(stack);

  // Reserve the next available frame pointer.
  result = stack->ptr++;

  result->call_info = call_info;
  result->call_info->depth = (int)(stack->ptr - stack->start); // shortening of 64 bit into 32;
  result->passes = 0;

  result->start_time = measurement;
  result->pause_time = -1; // init as not paused.
  result->switch_time = 0;
  result->wait_time = 0;
  result->child_time = 0;
  result->dead_time = 0;

  method = call_info->target;

  /* If the method was visited previously, it's recursive. */
  if (method->visits > 0)
  {
    method->recursive = 1;
    call_info->recursive = 1;
  }
  /* Enter the method. */
  method->visits++;

  // Unpause the parent frame, if it exists.
  // If currently paused then:
  //   1) The child frame will begin paused.
  //   2) The parent will inherit the child's dead time.
  prof_frame_unpause(parent_frame, measurement);

  if (paused) {
    prof_frame_pause(result, measurement);
  }

  // Return the result
  return result;
}

prof_frame_t *
prof_stack_pop(prof_stack_t *stack, double measurement)
{
  prof_frame_t *frame;
  prof_frame_t *parent_frame;
  prof_call_info_t *call_info;
  prof_method_t *method;

  double total_time;
  double self_time;

  frame = prof_stack_peek(stack);

  /* Frame can be null, which means the stack is empty.  This can happen if
     RubProf.start is called from a method that exits.  And it can happen if an
     exception is raised in code that is being profiled and the stack unwinds
     (RubyProf is not notified of that by the ruby runtime. */
  if (!frame) {
    return NULL;
  }

  /* Match passes until we reach the frame itself. */
  if (prof_frame_is_pass(frame)) {
    frame->passes--;
    /* Additional frames can be consumed. See pop_frames(). */
    return frame;
  }

  /* Consume this frame. */
  stack->ptr--;

  /* Calculate the total time this method took */
  prof_frame_unpause(frame, measurement);
  total_time = measurement - frame->start_time - frame->dead_time;
  self_time = total_time - frame->child_time - frame->wait_time;

  /* Update information about the current method */
  call_info = frame->call_info;
  method = call_info->target;

  call_info->called++;
  call_info->total_time += total_time;
  call_info->self_time += self_time;
  call_info->wait_time += frame->wait_time;

  /* Leave the method. */
  method->visits--;

  parent_frame = prof_stack_peek(stack);
  if (parent_frame)
  {
      parent_frame->child_time += total_time;
      parent_frame->dead_time += frame->dead_time;

      call_info->line = parent_frame->line;
  }

  return frame;
}

prof_frame_t *
prof_stack_pass(prof_stack_t *stack)
{
  prof_frame_t *frame = prof_stack_peek(stack);
  if (frame) {
    frame->passes++;
  }
  return frame;
}
