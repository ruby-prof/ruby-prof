/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* ruby-prof tracks the time spent executing every method in ruby programming.
   The main players are:

     profile_t         - This represents 1 profile.
     thread_data_t     - Stores data about a single thread.
     prof_stack_t      - The method call stack in a particular thread
     prof_method_t     - Profiling information about each method
     prof_call_info_t  - Keeps track a method's callers and callees.

  The final result is an instance of a profile object which has a hash table of
  thread_data_t, keyed on the thread id.  Each thread in turn has a hash table
  of prof_method_t, keyed on the method id.  A hash table is used for quick 
  look up when doing a profile.  However, it is exposed to Ruby as an array.

  Each prof_method_t has two hash tables, parent and children, of prof_call_info_t.
  These objects keep track of a method's callers (who called the method) and its
  callees (who the method called).  These are keyed the method id, but once again,
  are exposed to Ruby as arrays.  Each prof_call_into_t maintains a pointer to the
  caller or callee method, thereby making it easy to navigate through the call
  hierarchy in ruby - which is very helpful for creating call graphs.
*/

#include "ruby_prof.h"

#include "rp_allocation.h"
#include "rp_measure.h"
#include "rp_method.h"
#include "rp_call_info.h"
#include "rp_profile.h"
#include "rp_stack.h"
#include "rp_thread.h"

VALUE mProf;
VALUE cProfile;

/* support tracing ruby events from ruby-prof. useful for getting at
   what actually happens inside the ruby interpreter (and ruby-prof).
   set environment variable RUBY_PROF_TRACE to filename you want to
   find the trace in.
 */
FILE* trace_file = NULL;

static int
excludes_method(st_data_t key, prof_profile_t* profile)
{
    return (profile->exclude_methods_tbl &&
        method_table_lookup(profile->exclude_methods_tbl, key) != NULL);
}

static prof_method_t*
create_method(prof_profile_t* profile, st_data_t key, VALUE klass, VALUE msym, VALUE source_file, int source_line)
{
    prof_method_t* result = NULL;

    if (excludes_method(key, profile))
    {
        /* We found a exclusion sentinel so propagate it into the thread's local hash table. */
        /* TODO(nelgau): Is there a way to avoid this allocation completely so that all these
           tables share the same exclusion method struct? The first attempt failed due to my
           ignorance of the whims of the GC. */
        result = prof_method_create_excluded(klass, msym);
    }
    else
    {
        result = prof_method_create(klass, msym, source_file, source_line);
    }

    /* Insert the newly created method, or the exlcusion sentinel. */
    method_table_insert(profile->last_thread_data->method_table, result->key, result);

    return result;
}

static const char *
get_event_name(rb_event_flag_t event)
{
  switch (event) {
  case RUBY_EVENT_LINE:
    return "line";
  case RUBY_EVENT_CLASS:
    return "class";
  case RUBY_EVENT_END:
    return "end";
  case RUBY_EVENT_CALL:
    return "call";
  case RUBY_EVENT_RETURN:
    return "return";
  case RUBY_EVENT_B_CALL:
      return "b-call";
  case RUBY_EVENT_B_RETURN:
      return "b-return";
  case RUBY_EVENT_C_CALL:
    return "c-call";
  case RUBY_EVENT_C_RETURN:
    return "c-return";
  case RUBY_EVENT_THREAD_BEGIN:
      return "thread-begin";
  case RUBY_EVENT_THREAD_END:
      return "thread-end";
  case RUBY_EVENT_FIBER_SWITCH:
      return "fiber-switch";
  case RUBY_EVENT_RAISE:
    return "raise";
  default:
    return "unknown";
  }
}

/* ===========  Profiling ================= */
thread_data_t* check_fiber(prof_profile_t *profile, double measurement)
{
    thread_data_t* result = NULL;

    /* Get the current thread and fiber information. */
    VALUE fiber = rb_fiber_current();

    /* We need to switch the profiling context if we either had none before,
       we don't merge fibers and the fiber ids differ, or the thread ids differ. */
    if (profile->last_thread_data->fiber != fiber)
    {
        result = threads_table_lookup(profile, fiber);
        if (!result)
        {
            result = threads_table_insert(profile, fiber);
        }
        switch_thread(profile, result, measurement);
    }
    else
    {
        result = profile->last_thread_data;
    }
    return result;
}

static void
prof_trace(prof_profile_t* profile, rb_trace_arg_t *trace_arg, double measurement)
{
    static VALUE last_fiber = Qnil;
    VALUE fiber = rb_fiber_current();

    rb_event_flag_t event = rb_tracearg_event_flag(trace_arg);
    const char* event_name = get_event_name(event);

    VALUE source_file = rb_tracearg_path(trace_arg);
    int source_line = FIX2INT(rb_tracearg_lineno(trace_arg));
    VALUE msym = rb_tracearg_method_id(trace_arg);

    unsigned int klass_flags;
    VALUE klass = rb_tracearg_defined_class(trace_arg);
    VALUE resolved_klass = resolve_klass(klass, &klass_flags);
    const char* class_name = "";

    if (resolved_klass != Qnil)
        class_name = rb_class2name(resolved_klass);

    if (last_fiber != fiber)
    {
        fprintf(trace_file, "\n");
    }

    const char* method_name_char = (msym != Qnil ? rb_id2name(SYM2ID(msym)) : "");
    const char* source_file_char = (source_file != Qnil ? StringValuePtr(source_file) : "");

    fprintf(trace_file, "%2lu:%2f %-8s %s#%s    %s:%2d\n",
        FIX2ULONG(fiber), (double) measurement,
            event_name, class_name, method_name_char, source_file_char, source_line);
    fflush(trace_file);
    last_fiber = fiber;
}

static void
prof_event_hook(VALUE trace_point, void* data)
{
    prof_profile_t* profile = (prof_profile_t*)data;
    thread_data_t* thread_data = NULL;
    prof_frame_t *frame = NULL;
    double measurement;

    rb_trace_arg_t* trace_arg = rb_tracearg_from_tracepoint(trace_point);
    rb_event_flag_t event = rb_tracearg_event_flag(trace_arg);
    VALUE self = rb_tracearg_self(trace_arg);

    /* Get current measurement */
    measurement = prof_measure(profile->measurer);

    if (trace_file != NULL)
    {
        prof_trace(profile, trace_arg, measurement);
    }

    /* Special case - skip any methods from the mProf
       module since they clutter the results but aren't important to them results. */
    if (self == mProf)
        return;

    thread_data = check_fiber(profile, measurement);

    if (!thread_data->trace)
        return;

    /* Get the current frame for the current thread. */
    frame = thread_data->stack->ptr;

    switch (event)
    {
        case RUBY_EVENT_LINE:
        {
            /* Keep track of the current line number in this method.  When
               a new method is called, we know what line number it was
               called from. */
            if (frame->call_info)
            {
                if (prof_frame_is_real(frame))
                {
                    frame->source_file = rb_tracearg_path(trace_arg);
                    frame->source_line = FIX2INT(rb_tracearg_lineno(trace_arg));
                }
                break;
            }

            /* If we get here there was no frame, which means this is
               the first method seen for this thread, so fall through
               to below to create it. */
        }
        case RUBY_EVENT_CALL:
        case RUBY_EVENT_C_CALL:
        {
            prof_frame_t* next_frame;
            prof_call_info_t* call_info;
            prof_method_t* method;

            VALUE klass = rb_tracearg_defined_class(trace_arg);

            /* Special case - skip any methods from the mProf
               module or cProfile class since they clutter
               the results but aren't important to them results. */
            if (klass == cProfile)
                return;

            VALUE msym = rb_tracearg_method_id(trace_arg);
            st_data_t key = method_key(klass, msym);

            method = method_table_lookup(thread_data->method_table, key);

            if (!method)
            {
                VALUE source_file = (event != RUBY_EVENT_C_CALL ? rb_tracearg_path(trace_arg) : Qnil);
                int source_line = (event != RUBY_EVENT_C_CALL ? FIX2INT(rb_tracearg_lineno(trace_arg)) : 0);
                method = create_method(profile, key, klass, msym, source_file, source_line);
            }

            if (method->excluded)
            {
              prof_stack_pass(thread_data->stack);
              break;
            }

            if (!frame->call_info)
            {
                method->root = true;
                call_info = prof_call_info_create(method, NULL, method->source_file, method->source_line);
                st_insert(method->parent_call_infos, (st_data_t)&key, (st_data_t)call_info);
            }
            else
            {
                call_info = call_info_table_lookup(method->parent_call_infos, frame->call_info->method->key);

                if (!call_info)
                {
                    /* This call info does not yet exist.  So create it, then add
                       it to previous callinfo's children and to the current method .*/
                    call_info = prof_call_info_create(method, frame->call_info->method, frame->source_file, frame->source_line);
                    call_info_table_insert(method->parent_call_infos, frame->call_info->method->key, call_info);
                    call_info_table_insert(frame->call_info->method->child_call_infos, method->key, call_info);
                }
            }

            /* Push a new frame onto the stack for a new c-call or ruby call (into a method) */
            next_frame = prof_stack_push(thread_data->stack, call_info, measurement, RTEST(profile->paused));
            next_frame->source_file = method->source_file; 
            next_frame->source_line = method->source_line;
            break;
        } 
        case RUBY_EVENT_RETURN:
        case RUBY_EVENT_C_RETURN:
        {
            prof_stack_pop(thread_data->stack, measurement);
            break;
        }
        case RUBY_INTERNAL_EVENT_NEWOBJ:
        {
            /* We want to assign the allocations lexically, not the execution context (otherwise all allocations will
              show up under Class#new */
            int source_line = FIX2INT(rb_tracearg_lineno(trace_arg));
            VALUE source_file = rb_tracearg_path(trace_arg);

            if (!frame)
                return;

            for (int i = 0; i <= thread_data->stack->ptr - thread_data->stack->start - 1; i++)
            {
                prof_frame_t* a_frame = (thread_data->stack->ptr - i - 1);
                if (!a_frame)
                    return;

                if (!a_frame->call_info)
                    return;

                if (rb_str_equal(source_file, a_frame->call_info->method->source_file) &&
                    source_line >= a_frame->call_info->method->source_line)
                {
                    prof_allocate_increment(a_frame->call_info->method, trace_arg);
                }
            }
            break;
        }
    }
}

void
prof_install_hook(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);

    VALUE event_tracepoint = rb_tracepoint_new(Qnil,
        RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
        RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN |
        RUBY_EVENT_LINE,
        prof_event_hook, profile);
    rb_ary_push(profile->tracepoints, event_tracepoint);

    //VALUE allocation_tracepoint = rb_tracepoint_new(Qnil, RUBY_INTERNAL_EVENT_NEWOBJ, prof_event_hook, profile);
    //rb_ary_push(profile->tracepoints, allocation_tracepoint);

    for (int i = 0; i < RARRAY_LEN(profile->tracepoints); i++)
    {
        rb_tracepoint_enable(rb_ary_entry(profile->tracepoints, i));
    }
}

void
prof_remove_hook(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);

    for (int i = 0; i < RARRAY_LEN(profile->tracepoints); i++)
    {
        rb_tracepoint_disable(rb_ary_entry(profile->tracepoints, i));
    }
    rb_ary_clear(profile->tracepoints);
}

void Init_ruby_prof()
{
    mProf = rb_define_module("RubyProf");

    rp_init_allocation();
    rp_init_call_info();
    rp_init_measure();
    rp_init_method_info();
    rp_init_profile();
    rp_init_thread();
}
