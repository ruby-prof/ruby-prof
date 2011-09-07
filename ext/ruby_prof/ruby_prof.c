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

#include "rp_measure_process_time.h"
#include "rp_measure_wall_time.h"
#include "rp_measure_cpu_time.h"
#include "rp_measure_allocations.h"
#include "rp_measure_memory.h"
#include "rp_measure_gc_runs.h"
#include "rp_measure_gc_time.h"


/* =======  Globals  ========*/
static st_table *threads_tbl = NULL;
static st_table *exclude_threads_tbl = NULL;
static thread_data_t* last_thread_data = NULL;


/* =======  Helper Functions  ========*/
static VALUE figure_superclass(VALUE klass)
{
#if defined(HAVE_RB_CLASS_SUPERCLASS)
        // 1.9.3
        return rb_class_superclass(klass);
#elif defined(RCLASS_SUPER)
        return rb_class_real(RCLASS_SUPER(klass));
#else
        return rb_class_real(RCLASS(klass)->super);
#endif
}

  
  static VALUE
figure_singleton_name(VALUE klass)
{
    VALUE result = Qnil;

    /* We have come across a singleton object. First
       figure out what it is attached to.*/
    VALUE attached = rb_iv_get(klass, "__attached__");

    /* Is this a singleton class acting as a metaclass? */
    if (BUILTIN_TYPE(attached) == T_CLASS)
    {
        result = rb_str_new2("<Class::");
        rb_str_append(result, rb_inspect(attached));
        rb_str_cat2(result, ">");
    }

    /* Is this for singleton methods on a module? */
    else if (BUILTIN_TYPE(attached) == T_MODULE)
    {
        result = rb_str_new2("<Module::");
        rb_str_append(result, rb_inspect(attached));
        rb_str_cat2(result, ">");
    }

    /* Is this for singleton methods on an object? */
    else if (BUILTIN_TYPE(attached) == T_OBJECT)
    {
        /* Make sure to get the super class so that we don't
           mistakenly grab a T_ICLASS which would lead to
           unknown method errors. */
        VALUE super = figure_superclass(klass);
        result = rb_str_new2("<Object::");
        rb_str_append(result, rb_inspect(super));
        rb_str_cat2(result, ">");
    }

    /* Ok, this could be other things like an array made put onto
       a singleton object (yeah, it happens, see the singleton
       objects test case). */
    else
    {
        result = rb_inspect(klass);
    }

    return result;
}

static VALUE
klass_name(VALUE klass)
{
    VALUE result = Qnil;

    if (klass == 0 || klass == Qnil)
    {
        result = rb_str_new2("Global");
    }
    else if (BUILTIN_TYPE(klass) == T_MODULE)
    {
        result = rb_inspect(klass);
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON))
    {
        result = figure_singleton_name(klass);
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS)
    {
        result = rb_inspect(klass);
    }
    else
    {
        /* Should never happen. */
        result = rb_str_new2("Unknown");
    }

    return result;
}

static VALUE
method_name(ID mid)
{
    VALUE result;

    if (mid == ID_ALLOCATOR)
        result = rb_str_new2("allocate");
    else if (mid == 0)
        result = rb_str_new2("[No method]");
    else
        result = rb_String(ID2SYM(mid));

    return result;
}

static VALUE
full_name(VALUE klass, ID mid)
{
  VALUE result = klass_name(klass);
  rb_str_cat2(result, "#");
  rb_str_append(result, method_name(mid));

  return result;
}

/* =======  Method Key   ========*/
void
method_key(prof_method_key_t* key, VALUE klass, ID mid)
{
    key->klass = klass;
    key->mid = mid;
    key->key = (klass << 4) + (mid << 2);
}



/* =======  Profiling    ========*/
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
update_result(prof_measure_t total_time,
              prof_frame_t *parent_frame,
              prof_frame_t *frame)
{
    prof_measure_t self_time = total_time - frame->child_time - frame->wait_time;
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
switch_thread(VALUE thread_id, prof_measure_t now)
{
        prof_frame_t *frame = NULL;
        prof_measure_t wait_time = 0;
    /* Get new thread information. */
    thread_data_t *thread_data = threads_table_lookup(threads_tbl, thread_id);

    /* How long has this thread been waiting? */
    wait_time = now - thread_data->last_switch;

    thread_data->last_switch = now; // XXXX a test that fails if this is 0

    /* Get the frame at the top of the stack.  This may represent
       the current method (EVENT_LINE, EVENT_RETURN)  or the
       previous method (EVENT_CALL).*/
    frame = stack_peek(thread_data->stack);

    if (frame) {
      frame->wait_time += wait_time;
    }

    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (last_thread_data) {
      last_thread_data->last_switch = now;
    }

    last_thread_data = thread_data;
    return thread_data;
}

static prof_frame_t*
pop_frame(thread_data_t *thread_data, prof_measure_t now)
{
  prof_frame_t *frame = NULL;
  prof_frame_t* parent_frame = NULL;
  prof_measure_t total_time;

  frame = stack_pop(thread_data->stack); // only time it's called
  /* Frame can be null.  This can happen if RubProf.start is called from
     a method that exits.  And it can happen if an exception is raised
     in code that is being profiled and the stack unwinds (RubyProf is
     not notified of that by the ruby runtime. */
  if (frame == NULL) return NULL;

  /* Calculate the total time this method took */
  total_time = now - frame->start_time;

  parent_frame = stack_peek(thread_data->stack);
  if (parent_frame)
  {
        parent_frame->child_time += total_time;
  }

  update_result(total_time, parent_frame, frame); // only time it's called
  return frame;
}

static int
pop_frames(st_data_t key, st_data_t value, st_data_t now_arg)
{
    VALUE thread_id = (VALUE)key;
    thread_data_t* thread_data = (thread_data_t *) value;
    prof_measure_t now = *(prof_measure_t *) now_arg;

    if (!last_thread_data || last_thread_data->thread_id != thread_id)
      thread_data = switch_thread(thread_id, now);
    else
      thread_data = last_thread_data;

    while (pop_frame(thread_data, now))
    {
    }

    return ST_CONTINUE;
}

static void
prof_pop_threads(prof_measure_t now)
{
    st_foreach(threads_tbl, pop_frames, (st_data_t) &now);
}

#ifdef RUBY_VM
static void
prof_event_hook(rb_event_flag_t event, VALUE data, VALUE self, ID mid, VALUE klass)
#else
static void
prof_event_hook(rb_event_flag_t event, NODE *node, VALUE self, ID mid, VALUE klass)
#endif
{
    VALUE thread = Qnil;
    VALUE thread_id = Qnil;
    prof_measure_t now = 0;
    thread_data_t* thread_data = NULL;
    prof_frame_t *frame = NULL;

    #ifdef RUBY_VM
      if (event != RUBY_EVENT_C_CALL && event != RUBY_EVENT_C_RETURN) {
        // guess these are already set for C calls in 1.9, then?
        rb_frame_method_id_and_class(&mid, &klass);
      }
    #endif

    /* Get current timestamp */
    now = get_measurement();

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
               (unsigned int) thread_id, (unsigned int) now, event_name, source_file, source_line, class_name, method_name);
        /* fflush(trace_file); */
        last_thread_id = thread_id;
    }

    /* Special case - skip any methods from the mProf
       module, such as Prof.stop, since they clutter
       the results but aren't important to them results. */
    if (self == mProf) return;

    /* Get the current thread information. */
    thread = rb_thread_current();
    thread_id = rb_obj_id(thread);

    if (exclude_threads_tbl &&
        st_lookup(exclude_threads_tbl, (st_data_t) thread_id, 0))
    {
      return;
    }


    /* Was there a context switch? */
    if (!last_thread_data || last_thread_data->thread_id != thread_id)
      thread_data = switch_thread(thread_id, now);
    else
      thread_data = last_thread_data;


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
        frame->start_time = now;
        frame->wait_time = 0;
        frame->child_time = 0;
        frame->line = rb_sourceline();
        break;
    }
    case RUBY_EVENT_RETURN:
    case RUBY_EVENT_C_RETURN:
    {
        frame = pop_frame(thread_data, now);
      break;
    }
  }
}

/* call-seq:
   measure_mode -> measure_mode

   Returns what ruby-prof is measuring.  Valid values include:

   *RubyProf::PROCESS_TIME - Measure process time.  This is default.  It is implemented using the clock functions in the C Runtime library.
   *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows
   *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms.
   *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
   *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
   *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
   *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/
static VALUE
prof_get_measure_mode(VALUE self)
{
    return INT2NUM(measure_mode);
}

/* call-seq:
   measure_mode=value -> void

   Specifies what ruby-prof should measure.  Valid values include:

   *RubyProf::PROCESS_TIME - Measure process time.  This is default.  It is implemented using the clock functions in the C Runtime library.
   *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows
   *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms.
   *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
   *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
   *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
   *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/
static VALUE
prof_set_measure_mode(VALUE self, VALUE val)
{
    int mode = NUM2INT(val);

    if (threads_tbl)
    {
      rb_raise(rb_eRuntimeError, "can't set measure_mode while profiling");
    }

    switch (mode) {
      case MEASURE_PROCESS_TIME:
        get_measurement = measure_process_time;
        convert_measurement = convert_process_time;
        break;

      case MEASURE_WALL_TIME:
        get_measurement = measure_wall_time;
        convert_measurement = convert_wall_time;
        break;

      #if defined(MEASURE_CPU_TIME)
      case MEASURE_CPU_TIME:
        if (cpu_frequency == 0)
            cpu_frequency = get_cpu_frequency();
        get_measurement = measure_cpu_time;
        convert_measurement = convert_cpu_time;
        break;
      #endif

      #if defined(MEASURE_ALLOCATIONS)
      case MEASURE_ALLOCATIONS:
        get_measurement = measure_allocations;
        convert_measurement = convert_allocations;
        break;
      #endif

      #if defined(MEASURE_MEMORY)
      case MEASURE_MEMORY:
        get_measurement = measure_memory;
        convert_measurement = convert_memory;
        break;
      #endif

      #if defined(MEASURE_GC_RUNS)
      case MEASURE_GC_RUNS:
        get_measurement = measure_gc_runs;
        convert_measurement = convert_gc_runs;
        break;
      #endif

      #if defined(MEASURE_GC_TIME)
      case MEASURE_GC_TIME:
        get_measurement = measure_gc_time;
        convert_measurement = convert_gc_time;
        break;
      #endif

      default:
        rb_raise(rb_eArgError, "invalid mode: %d", mode);
        break;
    }

    measure_mode = mode;
    return val;
}

/* call-seq:
   exclude_threads= -> void

   Specifies what threads ruby-prof should exclude from profiling */
static VALUE
prof_set_exclude_threads(VALUE self, VALUE threads)
{
    int i;

    if (threads_tbl != NULL)
    {
      rb_raise(rb_eRuntimeError, "can't set exclude_threads while profiling");
    }

    /* Stay simple, first free the old hash table */
    if (exclude_threads_tbl)
    {
      st_free_table(exclude_threads_tbl);
      exclude_threads_tbl = NULL;
    }

    /* Now create a new one if the user passed in any threads */
    if (threads != Qnil)
    {
      Check_Type(threads, T_ARRAY);
      exclude_threads_tbl = st_init_numtable();

      for (i=0; i < RARRAY_LEN(threads); ++i)
      {
        VALUE thread = rb_ary_entry(threads, i);
        st_insert(exclude_threads_tbl, (st_data_t) rb_obj_id(thread), 0);
      }
    }
    return threads;
}


/* ===========  Profiling ================= */
void
prof_install_hook()
{
#ifdef RUBY_VM
    rb_add_event_hook(prof_event_hook,
          RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
          RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN
            | RUBY_EVENT_LINE, Qnil); // RUBY_EVENT_SWITCH
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


/* call-seq:
   running? -> boolean

   Returns whether a profile is currently running.*/
static VALUE
prof_running(VALUE self)
{
    if (threads_tbl != NULL)
        return Qtrue;
    else
        return Qfalse;
}

/* call-seq:
   start -> RubyProf

   Starts recording profile data.*/
static VALUE
prof_start(VALUE self)
{
	char* trace_file_name;
    if (threads_tbl != NULL)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was already called");
    }

    /* Setup globals */
    last_thread_data = NULL;
    threads_tbl = threads_table_create();

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

    prof_install_hook();
    return self;
}

/* call-seq:
   pause -> RubyProf

   Pauses collecting profile data. */
static VALUE
prof_pause(VALUE self)
{
    if (threads_tbl == NULL)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    prof_remove_hook();
    return self;
}

/* call-seq:
   resume {block} -> RubyProf

   Resumes recording profile data.*/
static VALUE
prof_resume(VALUE self)
{
    if (threads_tbl == NULL)
    {
        prof_start(self);
    }
    else
    {
        prof_install_hook();
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
    VALUE result = Qnil;

	/* get 'now' before prof emove hook because it calls GC.disable_stats
      which makes the call within prof_pop_threads of now return 0, which is wrong
    */
    prof_measure_t now = get_measurement();
    if (threads_tbl == NULL)
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

    prof_pop_threads(now);

    /* Create the result */
    result = prof_result_new(threads_tbl);

    /* Unset the last_thread_data (very important!)
       and the threads table */
    last_thread_data = NULL;
    threads_table_free(threads_tbl);
    threads_tbl = NULL;

    /* compute minimality of call_infos */
    rb_funcall(result, rb_intern("compute_minimality") , 0);

    return result;
}

/* call-seq:
   profile {block} -> RubyProf::Result

Profiles the specified block and returns a RubyProf::Result object. */
static VALUE
prof_profile(VALUE self)
{
    int result;

    if (!rb_block_given_p())
    {
        rb_raise(rb_eArgError, "A block must be provided to the profile method.");
    }

    prof_start(self);
    rb_protect(rb_yield, self, &result);
    return prof_stop(self);
}

/* Get around annoying limitations in RDOC */

/* Document-method: measure_process_time
   call-seq:
     measure_process_time -> float

Returns the process time.*/

/* Document-method: measure_wall_time
   call-seq:
     measure_wall_time -> float

Returns the wall time.*/

/* Document-method: measure_cpu_time
   call-seq:
     measure_cpu_time -> float

Returns the cpu time.*/

/* Document-method: get_cpu_frequency
   call-seq:
     cpu_frequency -> int

Returns the cpu's frequency.  This value is needed when
RubyProf::measure_mode is set to CPU_TIME. */

/* Document-method: cpu_frequency
   call-seq:
     cpu_frequency -> int

Returns the cpu's frequency.  This value is needed when
RubyProf::measure_mode is set to CPU_TIME. */

/* Document-method: cpu_frequency=
   call-seq:
     cpu_frequency = frequency

Sets the cpu's frequency.  This value is needed when
RubyProf::measure_mode is set to CPU_TIME. */

/* Document-method: measure_allocations
   call-seq:
     measure_allocations -> int

Returns the total number of object allocations since Ruby started.*/

/* Document-method: measure_memory
   call-seq:
     measure_memory -> int

Returns total allocated memory in bytes.*/

/* Document-method: measure_gc_runs
   call-seq:
     gc_runs -> Integer

Returns the total number of garbage collections.*/

/* Document-method: measure_gc_time
   call-seq:
     gc_time -> Integer

Returns the time spent doing garbage collections in microseconds.*/

void Init_ruby_prof()
{
    mProf = rb_define_module("RubyProf");
    
    rp_init_method_info();
    rp_init_call_info();
    rp_init_result();

    rb_define_const(mProf, "VERSION", rb_str_new2(RUBY_PROF_VERSION));
    rb_define_module_function(mProf, "start", prof_start, 0);
    rb_define_module_function(mProf, "stop", prof_stop, 0);
    rb_define_module_function(mProf, "resume", prof_resume, 0);
    rb_define_module_function(mProf, "pause", prof_pause, 0);
    rb_define_module_function(mProf, "running?", prof_running, 0);
    rb_define_module_function(mProf, "profile", prof_profile, 0);

    rb_define_singleton_method(mProf, "exclude_threads=", prof_set_exclude_threads, 1);
    rb_define_singleton_method(mProf, "measure_mode", prof_get_measure_mode, 0);
    rb_define_singleton_method(mProf, "measure_mode=", prof_set_measure_mode, 1);

    rb_define_const(mProf, "CLOCKS_PER_SEC", INT2NUM(CLOCKS_PER_SEC));
    rb_define_const(mProf, "PROCESS_TIME", INT2NUM(MEASURE_PROCESS_TIME));
    rb_define_singleton_method(mProf, "measure_process_time", prof_measure_process_time, 0); /* in measure_process_time.h */
    rb_define_const(mProf, "WALL_TIME", INT2NUM(MEASURE_WALL_TIME));
    rb_define_singleton_method(mProf, "measure_wall_time", prof_measure_wall_time, 0); /* in measure_wall_time.h */

    #ifndef MEASURE_CPU_TIME
    rb_define_const(mProf, "CPU_TIME", Qnil);
    #else
    rb_define_const(mProf, "CPU_TIME", INT2NUM(MEASURE_CPU_TIME));
    rb_define_singleton_method(mProf, "measure_cpu_time", prof_measure_cpu_time, 0); /* in measure_cpu_time.h */
    rb_define_singleton_method(mProf, "cpu_frequency", prof_get_cpu_frequency, 0); /* in measure_cpu_time.h */
    rb_define_singleton_method(mProf, "cpu_frequency=", prof_set_cpu_frequency, 1); /* in measure_cpu_time.h */
    #endif

    #ifndef MEASURE_ALLOCATIONS
    rb_define_const(mProf, "ALLOCATIONS", Qnil);
    #else
    rb_define_const(mProf, "ALLOCATIONS", INT2NUM(MEASURE_ALLOCATIONS));
    rb_define_singleton_method(mProf, "measure_allocations", prof_measure_allocations, 0); /* in measure_allocations.h */
    #endif

    #ifndef MEASURE_MEMORY
    rb_define_const(mProf, "MEMORY", Qnil);
    #else
    rb_define_const(mProf, "MEMORY", INT2NUM(MEASURE_MEMORY));
    rb_define_singleton_method(mProf, "measure_memory", prof_measure_memory, 0); /* in measure_memory.h */
    #endif

    #ifndef MEASURE_GC_RUNS
    rb_define_const(mProf, "GC_RUNS", Qnil);
    #else
    rb_define_const(mProf, "GC_RUNS", INT2NUM(MEASURE_GC_RUNS));
    rb_define_singleton_method(mProf, "measure_gc_runs", prof_measure_gc_runs, 0); /* in measure_gc_runs.h */
    #endif

    #ifndef MEASURE_GC_TIME
    rb_define_const(mProf, "GC_TIME", Qnil);
    #else
    rb_define_const(mProf, "GC_TIME", INT2NUM(MEASURE_GC_TIME));
    rb_define_singleton_method(mProf, "measure_gc_time", prof_measure_gc_time, 0); /* in measure_gc_time.h */
    #endif
}
