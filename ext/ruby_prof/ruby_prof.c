/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

/* ruby-prof tracks the time spent executing every method in ruby programming.
   The main players are:

     prof_result_t     - Its one field, values,  contains the overall results
     thread_data_t     - Stores data about a single thread.
     prof_stack_t      - The method call stack in a particular thread
     prof_method_t     - Profiling information for each method
     prof_call_info_t  - Keeps track a method's callers and callees.

  The final resulut is a hash table of thread_data_t, keyed on the thread
  id.  Each thread has an hash a table of prof_method_t, keyed on the
  method id.  A hash table is used for quick look up when doing a profile.
  However, it is exposed to Ruby as an array.

  Each prof_method_t has two hash tables, parent and children, of prof_call_info_t.
  These objects keep track of a method's callers (who called the method) and its
  callees (who the method called).  These are keyed the method id, but once again,
  are exposed to Ruby as arrays.  Each prof_call_into_t maintains a pointer to the
  caller or callee method, thereby making it easy to navigate through the call
  hierarchy in ruby - which is very helpful for creating call graphs.
*/

#include "ruby_prof.h"
#include <stdio.h>
#include <assert.h>

static prof_profile_t*
prof_get_profile(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       endinging up in endless recursion. */
    return (prof_profile_t*)RDATA(self)->data;
}

void
method_key(prof_method_key_t* key, VALUE klass, ID mid)
{
    key->klass = klass;
    key->mid = mid;
    key->key = (klass << 4) + (mid << 2);
}

/* support tracing ruby events from ruby-prof. useful for getting at
   what actually happens inside the ruby interpreter (and ruby-prof).
   set environment variable RUBY_PROF_TRACE to filename you want to
   find the trace in.
 */
static FILE* trace_file = NULL;

/* Copied from eval.c (1.8.x) / thread.c (1.9.2) */
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
    case RUBY_EVENT_C_CALL:
  return "c-call";
    case RUBY_EVENT_C_RETURN:
  return "c-return";
    case RUBY_EVENT_RAISE:
  return "raise";

#ifdef RUBY_VM
    case RUBY_EVENT_SWITCH:
  return "thread-interrupt";
#endif

    default:
  return "unknown";
  }
}


static prof_method_t*
#ifdef RUBY_VM
 get_method(rb_event_flag_t event, VALUE klass, ID mid, st_table* method_table)
# else
 get_method(rb_event_flag_t event, NODE *node, VALUE klass, ID mid, st_table* method_table)
#endif
{
    prof_method_key_t key;
    prof_method_t *method = NULL;

    method_key(&key, klass, mid);
    method = method_table_lookup(method_table, &key);

    if (!method)
    {
      const char* source_file = rb_sourcefile();
      int line = rb_sourceline();

      /* Line numbers are not accurate for c method calls */
      if (event == RUBY_EVENT_C_CALL)
      {
        line = 0;
        source_file = NULL;
      }

      method = prof_method_create(&key, source_file, line);
      method_table_insert(method_table, method->key, method);
    }
    return method;
}

static void
update_result(double total_time,
              prof_frame_t *parent_frame,
              prof_frame_t *frame)
{
    double self_time = total_time - frame->child_time - frame->wait_time;
    prof_call_info_t *call_info = frame->call_info;

    /* Update information about the current method */
    call_info->called++;
    call_info->total_time += total_time;
    call_info->self_time += self_time;
    call_info->wait_time += frame->wait_time;

    /* Note where the current method was called from */
    if (parent_frame)
      call_info->line = parent_frame->line;
}

static thread_data_t *
switch_thread(prof_profile_t* profile, VALUE thread_id)
{
    prof_frame_t *frame = NULL;
    double wait_time = 0;

    /* Get new thread information. */
    thread_data_t *thread_data = threads_table_lookup(profile->threads_tbl, thread_id);

    /* How long has this thread been waiting? */
    wait_time = profile->measurement - thread_data->last_switch;

    thread_data->last_switch = profile->measurement; // XXXX a test that fails if this is 0

    /* Get the frame at the top of the stack.  This may represent
       the current method (EVENT_LINE, EVENT_RETURN)  or the
       previous method (EVENT_CALL).*/
    frame = stack_peek(thread_data->stack);

    if (frame) {
      frame->wait_time += wait_time;
    }

    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (profile->last_thread_data) {
      profile->last_thread_data->last_switch = profile->measurement;
    }

    profile->last_thread_data = thread_data;
    return thread_data;
}

static prof_frame_t*
pop_frame(prof_profile_t* profile, thread_data_t *thread_data)
{
  prof_frame_t *frame = NULL;
  prof_frame_t* parent_frame = NULL;
  double total_time;

  frame = stack_pop(thread_data->stack); // only time it's called
  /* Frame can be null.  This can happen if RubProf.start is called from
     a method that exits.  And it can happen if an exception is raised
     in code that is being profiled and the stack unwinds (RubyProf is
     not notified of that by the ruby runtime. */
  if (frame == NULL) return NULL;

  /* Calculate the total time this method took */
  total_time = profile->measurement - frame->start_time;

  parent_frame = stack_peek(thread_data->stack);
  if (parent_frame)
  {
        parent_frame->child_time += total_time;
  }

  update_result(total_time, parent_frame, frame); // only time it's called
  return frame;
}

static int
pop_frames(st_data_t key, st_data_t value, st_data_t data)
{
    VALUE thread_id = (VALUE)key;
    thread_data_t* thread_data = (thread_data_t *) value;
    prof_profile_t* profile = (prof_profile_t*) data;

    if (!profile->last_thread_data || profile->last_thread_data->thread_id != thread_id)
      thread_data = switch_thread(profile, thread_id);
    else
      thread_data = profile->last_thread_data;

    while (pop_frame(profile, thread_data))
    {
    }

    return ST_CONTINUE;
}

static void
prof_pop_threads(prof_profile_t* profile)
{
    st_foreach(profile->threads_tbl, pop_frames, (st_data_t) profile);
}

#ifdef RUBY_VM
static void
prof_event_hook(rb_event_flag_t event, VALUE data, VALUE self, ID mid, VALUE klass)
#else
static void
prof_event_hook(rb_event_flag_t event, NODE *node, VALUE self, ID mid, VALUE klass)
#endif
{
    prof_profile_t* profile = prof_get_profile(data);
    VALUE thread = Qnil;
    VALUE thread_id = Qnil;
    thread_data_t* thread_data = NULL;
    prof_frame_t *frame = NULL;

    #ifdef RUBY_VM
      if (event != RUBY_EVENT_C_CALL && event != RUBY_EVENT_C_RETURN) {
        // guess these are already set for C calls in 1.9, then?
        rb_frame_method_id_and_class(&mid, &klass);
      }
    #endif

    /* Get current measurement */
    profile->measurement = measure->measure();

    if (trace_file != NULL)
    {
        static VALUE last_thread_id = Qnil;

        VALUE thread = rb_thread_current();
        VALUE thread_id = rb_obj_id(thread);
        const char* class_name = NULL;
        const char* method_name = rb_id2name(mid);
        const char* source_file = rb_sourcefile();
        unsigned int source_line = rb_sourceline();

        const char* event_name = get_event_name(event);

        if (klass != 0)
          klass = (BUILTIN_TYPE(klass) == T_ICLASS ? RBASIC(klass)->klass : klass);

        class_name = rb_class2name(klass);

        if (last_thread_id != thread_id) {
          fprintf(trace_file, "\n");
        }

        fprintf(trace_file, "%2u:%2ums %-8s %s:%2d  %s#%s\n",
               (unsigned int) thread_id, (unsigned int) profile->measurement, event_name, source_file, source_line, class_name, method_name);
        /* fflush(trace_file); */
        last_thread_id = thread_id;
    }

    /* Special case - skip any methods from the mProf
       module or cProfile class since they clutter
       the results but aren't important to them results. */
    if (self == mProf || klass == cProfile) return;

    /* Get the current thread information. */
    thread = rb_thread_current();
    thread_id = rb_obj_id(thread);

    if (profile->exclude_threads_tbl &&
        st_lookup(profile->exclude_threads_tbl, (st_data_t) thread_id, 0))
    {
      return;
    }

    /* Was there a context switch? */
    if (!profile->last_thread_data || profile->last_thread_data->thread_id != thread_id)
      thread_data = switch_thread(profile, thread_id, profile->measurement);
    else
      thread_data = profile->last_thread_data;


    switch (event) {
    case RUBY_EVENT_LINE:
    {
      /* Keep track of the current line number in this method.  When
         a new method is called, we know what line number it was
         called from. */

       /* Get the current frame for the current thread. */
      frame = stack_peek(thread_data->stack);

      if (frame)
      {
        frame->line = rb_sourceline();
        break;
      }

      /* If we get here there was no frame, which means this is
         the first method seen for this thread, so fall through
         to below to create it. */
    }
    case RUBY_EVENT_CALL:
    case RUBY_EVENT_C_CALL:
    {
        prof_call_info_t *call_info = NULL;
        prof_method_t *method = NULL;

        /* Get the current frame for the current thread. */
        frame = stack_peek(thread_data->stack);

        /* Is this an include for a module?  If so get the actual
           module class since we want to combine all profiling
           results for that module. */

        if (klass != 0)
          klass = (BUILTIN_TYPE(klass) == T_ICLASS ? RBASIC(klass)->klass : klass);

        #ifdef RUBY_VM
        method = get_method(event, klass, mid, thread_data->method_table);
        #else
        method = get_method(event, node, klass, mid, thread_data->method_table);
        #endif

        if (!frame)
        {
          call_info = prof_call_info_create(method, NULL);
          prof_add_call_info(method->call_infos, call_info);
        }
        else
        {
          call_info = call_info_table_lookup(frame->call_info->call_infos, method->key);

          if (!call_info)
          {
            call_info = prof_call_info_create(method, frame->call_info);
            call_info_table_insert(frame->call_info->call_infos, method->key, call_info);
            prof_add_call_info(method->call_infos, call_info);
          }
        }

        /* Push a new frame onto the stack for a new c-call or ruby call (into a method) */
        frame = stack_push(thread_data->stack);
        frame->call_info = call_info;
        frame->start_time = profile->measurement;
        frame->wait_time = 0;
        frame->child_time = 0;
        frame->line = rb_sourceline();
        break;
    }
    case RUBY_EVENT_RETURN:
    case RUBY_EVENT_C_RETURN:
    {
        frame = pop_frame(profile, thread_data);
      break;
    }
  }
}


/* ===========  Profiling ================= */
void
prof_install_hook(VALUE self)
{
#ifdef RUBY_VM
    rb_add_event_hook(prof_event_hook,
          RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
          RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN
            | RUBY_EVENT_LINE, self); // RUBY_EVENT_SWITCH
#else
    rb_add_event_hook(prof_event_hook,
          RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
          RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN
          | RUBY_EVENT_LINE);
#endif

#if defined(TOGGLE_GC_STATS)
    rb_gc_enable_stats();
#endif
}

void
prof_remove_hook()
{
#if defined(TOGGLE_GC_STATS)
    rb_gc_disable_stats();
#endif

    /* Now unregister from event   */
    rb_remove_event_hook(prof_event_hook);
}


/* ========  Profile Class ====== */
static VALUE
prof_allocate(VALUE klass)
{
    VALUE result;
    prof_profile_t* profile;
    result = Data_Make_Struct(klass, prof_profile_t, NULL, NULL, profile);
    profile->running = Qfalse;
    return result;
}

/* call-seq:
   running? -> boolean

   Returns whether a profile is currently running.*/
static VALUE
prof_running(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    return profile->running;
}

/* call-seq:
   start -> RubyProf

   Starts recording profile data.*/
static VALUE
prof_start(VALUE self)
{
	  char* trace_file_name;
    prof_profile_t* profile = prof_get_profile(self);
        
    if (profile->running == Qtrue)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was already called");
    }

    profile->running = Qtrue;
    profile->last_thread_data = NULL;
    profile->threads_tbl = threads_table_create();

    /* open trace file if environment wants it */
    trace_file_name = getenv("RUBY_PROF_TRACE");
    if (trace_file_name != NULL) {
      if (0==strcmp(trace_file_name, "stdout")) {
        trace_file = stdout;
      } else if (0==strcmp(trace_file_name, "stderr")) {
        trace_file = stderr;
      } else {
        trace_file = fopen(trace_file_name, "a");
      }
    }

    prof_install_hook(self);
    return self;
}

/* call-seq:
   pause -> RubyProf

   Pauses collecting profile data. */
static VALUE
prof_pause(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    profile->running = Qfalse;

    prof_remove_hook();
    return self;
}

/* call-seq:
   resume {block} -> RubyProf

   Resumes recording profile data.*/
static VALUE
prof_resume(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    if (profile->running == Qfalse)
    {
        prof_start(self);
    }
    else
    {
        profile->running = Qtrue;
        prof_install_hook(self);
    }

    if (rb_block_given_p())
    {
      rb_ensure(rb_yield, self, prof_pause, self);
    }

    return self;
}

/* call-seq:
   stop -> RubyProf::Result

   Stops collecting profile data and returns a RubyProf::Result object. */
static VALUE
prof_stop(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    VALUE result = Qnil;

	/* get 'now' before prof emove hook because it calls GC.disable_stats
      which makes the call within prof_pop_threads of now return 0, which is wrong
    */
    profile->measurement = measure->measure();
    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was not yet called");
    }
  
    /* close trace file if open */
    if (trace_file != NULL) {
      if (trace_file!=stderr && trace_file!=stdout)
        fclose(trace_file);
      trace_file = NULL;
    }
    
    prof_remove_hook();

    prof_pop_threads(profile);

    /* Create the result */
    result = prof_result_new(profile->threads_tbl);

    /* Unset the last_thread_data (very important!)
       and the threads table */
    profile->running = Qfalse;
    profile->last_thread_data = NULL;
    threads_table_free(profile->threads_tbl);
    profile->threads_tbl = NULL;

    /* compute minimality of call_infos */
    rb_funcall(result, rb_intern("compute_minimality") , 0);

    return result;
}

/* call-seq:
   profile {block} -> RubyProf::Result

Profiles the specified block and returns a RubyProf::Result object. */
static VALUE
prof_profile(VALUE klass)
{
    int result;
    VALUE profile = rb_class_new_instance(0, 0, cProfile);

    if (!rb_block_given_p())
    {
        rb_raise(rb_eArgError, "A block must be provided to the profile method.");
    }

    prof_start(profile);
    rb_protect(rb_yield, profile, &result);
    return prof_stop(profile);
}

void Init_ruby_prof()
{
    mProf = rb_define_module("RubyProf");
    rb_define_const(mProf, "VERSION", rb_str_new2(RUBY_PROF_VERSION));
    rb_define_singleton_method(mProf, "exclude_threads=", prof_set_exclude_threads, 1);
    rb_define_singleton_method(mProf, "measure_mode", prof_get_measure_mode, 0);
    rb_define_singleton_method(mProf, "measure_mode=", prof_set_measure_mode, 1);
    
    rp_init_measure();
    rp_init_method_info();
    rp_init_call_info();
    rp_init_result();

    cProfile = rb_define_class_under(mProf, "Profile", rb_cObject);
    rb_define_singleton_method(cProfile, "profile", prof_profile, 0);
    rb_define_alloc_func (cProfile, prof_allocate);
    rb_define_method(cProfile, "start", prof_start, 0);
    rb_define_method(cProfile, "start", prof_start, 0);
    rb_define_method(cProfile, "stop", prof_stop, 0);
    rb_define_method(cProfile, "resume", prof_resume, 0);
    rb_define_method(cProfile, "pause", prof_pause, 0);
    rb_define_method(cProfile, "running?", prof_running, 0);
}
