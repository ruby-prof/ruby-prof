/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_stack.h"

#define INITIAL_STACK_SIZE 8


void
prof_frame_pause(prof_frame_t *frame, prof_measurements_t *current_measurements)
{
    if (frame && prof_frame_is_unpaused(frame)) {
        for(size_t i = 0; i < current_measurements->len; i++) {
            frame->measurements[i].pause = current_measurements->values[i];
        }
    }
}

void
prof_frame_unpause(prof_frame_t *frame, prof_measurements_t *current_measurements)
{
    if (frame && prof_frame_is_paused(frame)) {
        for(size_t i = 0; i < current_measurements->len; i++) {
            frame->measurements[i].dead += (current_measurements->values[i] - frame->measurements[i].pause);
            frame->measurements[i].pause = -1;
        }
    }
}

prof_frame_t*
prof_stack_frame_get(size_t measurements_len, size_t i, prof_frame_t *stack_start)
{
    size_t offset = i * FRAME_SIZE(measurements_len);

    return (prof_frame_t*)((uintptr_t)stack_start + offset);
}

/* Creates a stack of prof_frame_t to keep track
   of timings for active methods. */
prof_stack_t *
prof_stack_create(size_t measurements_len)
{
    prof_stack_t *stack = ALLOC(prof_stack_t);
    stack->measurements_len = measurements_len;
    stack->start = (prof_frame_t*) ruby_xmalloc2(INITIAL_STACK_SIZE, FRAME_SIZE(measurements_len));
    for (size_t i = 0; i < INITIAL_STACK_SIZE; i++) {
        prof_frame_t *frame = prof_stack_frame_get(measurements_len, i, stack->start);
        frame->measurements_len = measurements_len;
    }
    stack->ptr = stack->start;
    stack->end = (prof_frame_t*)((uintptr_t)(stack->start) +
        (INITIAL_STACK_SIZE * FRAME_SIZE(measurements_len)));

    return stack;
}

void
prof_stack_free(prof_stack_t *stack)
{
    xfree(stack->start);
    xfree(stack);
}

static void
prof_stack_realloc(prof_stack_t *stack, size_t measurements_len)
{

    size_t len = ((uintptr_t)(stack->ptr) - (uintptr_t)(stack->start)) / FRAME_SIZE(measurements_len);
    size_t new_capacity =
      (((uintptr_t)(stack->end) - (uintptr_t)(stack->start)) * 2) / FRAME_SIZE(measurements_len);

    stack->start =
        (prof_frame_t*) ruby_xrealloc2(
            (char*)(stack->start), new_capacity, FRAME_SIZE(measurements_len));

    for (int i = 0; i < new_capacity; i++) {
        prof_frame_t *frame = prof_stack_frame_get(measurements_len, i, stack->start);
        frame->measurements_len = measurements_len;
    }

    /* Memory just got moved, reset pointers */
    stack->ptr = (prof_frame_t*) ((uintptr_t)(stack->start) + len * FRAME_SIZE(measurements_len));
    stack->end = (prof_frame_t*) ((uintptr_t)(stack->start) + new_capacity * FRAME_SIZE(measurements_len));
}

prof_frame_t *
prof_stack_push(prof_stack_t *stack, prof_call_info_t *call_info, prof_measurements_t *measurements, int paused)
{
  prof_frame_t *result;
  prof_frame_t* parent_frame;
  prof_method_t *method;
  size_t measurements_len = stack->measurements_len;

  parent_frame = prof_stack_peek(stack);

  /* Is there space on the stack?  If not, double
     its size. */
  if (stack->ptr == stack->end)
  {
      prof_stack_realloc(stack, measurements_len);
  }

  // Reserve the next available frame pointer.
  result = stack->ptr;
  stack->ptr = NEXT_FRAME(stack);

  result->call_info = call_info;
  // shortening of 64 bit into 32;
  result->call_info->depth = (int)
      (((uintptr_t)(stack->ptr) - (uintptr_t)(stack->start)) / FRAME_SIZE(measurements_len));
  result->passes = 0;

  for (size_t i = 0; i < measurements_len; i++) {
      result->measurements[i].start = measurements->values[i];
      result->measurements[i].pause = -1; // init as not paused
      result->measurements[i].switch_t = 0;
      result->measurements[i].wait = 0;
      result->measurements[i].child = 0;
      result->measurements[i].dead = 0;
  }

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
  prof_frame_unpause(parent_frame, measurements);

  if (paused) {
    prof_frame_pause(result, measurements);
  }

  // Return the result
  return result;
}

prof_frame_t *
prof_stack_pop(prof_stack_t *stack, prof_measurements_t *measurements)
{
  prof_frame_t *frame;
  prof_frame_t *parent_frame;
  prof_call_info_t *call_info;
  prof_method_t *method;

  double total_time;
  double self_time;

  frame = prof_stack_peek(stack);

  /* Frame can be null.  This can happen if RubProf.start is called from
     a method that exits.  And it can happen if an exception is raised
     in code that is being profiled and the stack unwinds (RubyProf is
     not notified of that by the ruby runtime. */
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
  stack->ptr = PREVIOUS_FRAME(stack);

  prof_frame_unpause(frame, measurements);

  /* Update information about the current method */
  call_info = frame->call_info;
  method = call_info->target;

  call_info->called++;

  for (size_t i = 0; i < measurements->len; i++) {
      total_time = measurements->values[i] - frame->measurements[i].start - frame->measurements[i].dead;
      self_time = total_time - frame->measurements[i].child - frame->measurements[i].wait;

      call_info->measure_values[i].total += total_time;
      call_info->measure_values[i].self += self_time;
      call_info->measure_values[i].wait += frame->measurements[i].wait;
  }

  /* Leave the method. */
  method->visits--;

  parent_frame = prof_stack_peek(stack);
  if (parent_frame)
  {
      for (size_t i = 0; i < measurements->len; i++) {
          parent_frame->measurements[i].child +=
              measurements->values[i] - frame->measurements[i].start - frame->measurements[i].dead;
          parent_frame->measurements[i].dead += frame->measurements[i].dead;
      }

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
