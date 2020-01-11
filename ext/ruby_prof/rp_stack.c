/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_stack.h"

#define INITIAL_STACK_SIZE 32

void prof_frame_pause(prof_frame_t* frame, double current_measurement)
{
    if (frame && prof_frame_is_unpaused(frame))
        frame->pause_time = current_measurement;
}

void prof_frame_unpause(prof_frame_t* frame, double current_measurement)
{
    if (frame && prof_frame_is_paused(frame))
    {
        frame->dead_time += (current_measurement - frame->pause_time);
        frame->pause_time = -1;
    }
}

/* Creates a stack of prof_frame_t to keep track
   of timings for active methods. */
prof_stack_t* prof_stack_create()
{
    prof_stack_t* stack = ALLOC(prof_stack_t);
    stack->start = ZALLOC_N(prof_frame_t, INITIAL_STACK_SIZE);
    stack->ptr = stack->start;
    stack->end = stack->start + INITIAL_STACK_SIZE;

    return stack;
}

void prof_stack_free(prof_stack_t* stack)
{
    xfree(stack->start);
    xfree(stack);
}

prof_frame_t* prof_stack_push(prof_stack_t* stack, prof_call_tree_t* call_tree, double measurement, int paused)
{
    prof_frame_t* result;
    prof_frame_t* parent_frame;

    /* Is there space on the stack?  If not, double
     its size. */
    if (stack->ptr == stack->end - 1)
    {
        size_t len = stack->ptr - stack->start;
        size_t new_capacity = (stack->end - stack->start) * 2;
        REALLOC_N(stack->start, prof_frame_t, new_capacity);

        /* Memory just got moved, reset pointers */
        stack->ptr = stack->start + len;
        stack->end = stack->start + new_capacity;
    }

    parent_frame = stack->ptr;
    stack->ptr++;

    result = stack->ptr;
    result->call_tree = call_tree;
    result->call_tree->depth = (int)(stack->ptr - stack->start); // shortening of 64 bit into 32;
    result->passes = 0;

    result->start_time = measurement;
    result->pause_time = -1; // init as not paused.
    result->switch_time = 0;
    result->wait_time = 0;
    result->child_time = 0;
    result->dead_time = 0;
    result->source_file = Qnil;
    result->source_line = 0;

    call_tree->measurement->called++;
    call_tree->visits++;

    if (call_tree->method->visits > 0)
    {
        call_tree->method->recursive = true;
    }
    call_tree->method->measurement->called++;
    call_tree->method->visits++;

    // Unpause the parent frame, if it exists.
    // If currently paused then:
    //   1) The child frame will begin paused.
    //   2) The parent will inherit the child's dead time.
    prof_frame_unpause(parent_frame, measurement);

    if (paused)
    {
        prof_frame_pause(result, measurement);
    }

    // Return the result
    return result;
}

prof_frame_t* prof_stack_pop(prof_stack_t* stack, double measurement)
{
    prof_frame_t* frame;
    prof_frame_t* parent_frame;
    prof_call_tree_t* call_tree;

    double total_time;
    double self_time;

    if (stack->ptr == stack->start)
        return NULL;

    frame = stack->ptr;

    /* Match passes until we reach the frame itself. */
    if (prof_frame_is_pass(frame))
    {
        frame->passes--;
        /* Additional frames can be consumed. See pop_frames(). */
        return frame;
    }

    /* Consume this frame. */
    stack->ptr--;

    parent_frame = stack->ptr;

    /* Calculate the total time this method took */
    prof_frame_unpause(frame, measurement);

    total_time = measurement - frame->start_time - frame->dead_time;
    self_time = total_time - frame->child_time - frame->wait_time;

    /* Update information about the current method */
    call_tree = frame->call_tree;

    // Update method measurement
    call_tree->method->measurement->self_time += self_time;
    call_tree->method->measurement->wait_time += frame->wait_time;
    if (call_tree->method->visits == 1)
        call_tree->method->measurement->total_time += total_time;

    call_tree->method->visits--;

    // Update method measurement
    call_tree->measurement->self_time += self_time;
    call_tree->measurement->wait_time += frame->wait_time;
    if (call_tree->visits == 1)
        call_tree->measurement->total_time += total_time;

    call_tree->visits--;

    if (parent_frame)
    {
        parent_frame->child_time += total_time;
        parent_frame->dead_time += frame->dead_time;
    }

    return frame;
}

prof_frame_t* prof_stack_pass(prof_stack_t* stack)
{
    prof_frame_t* frame = stack->ptr;
    if (frame)
    {
        frame->passes++;
    }
    return frame;
}

prof_method_t* prof_find_method(prof_stack_t* stack, VALUE source_file, int source_line)
{
    prof_frame_t* frame = stack->ptr;
    while (frame >= stack->start)
    {
        if (!frame->call_tree)
            return NULL;

        if (rb_str_equal(source_file, frame->call_tree->method->source_file) &&
            source_line >= frame->call_tree->method->source_line)
        {
            return frame->call_tree->method;
        }
        frame--;
    }
    return NULL;
}
