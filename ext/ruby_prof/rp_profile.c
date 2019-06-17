/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include <assert.h>

#include "rp_profile.h"
#include "rp_call_info.h"
#include "rp_method.h"

VALUE cProfile;

prof_profile_t*
prof_get_profile(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    return DATA_PTR(self);
}

static int
collect_threads(st_data_t key, st_data_t value, st_data_t result)
{
    thread_data_t* thread_data = (thread_data_t*) value;
    if (thread_data->trace)
    {
        VALUE threads_array = (VALUE)result;
        rb_ary_push(threads_array, prof_thread_wrap(thread_data));
    }
    return ST_CONTINUE;
}

/* ========  Profile Class ====== */
static int
mark_threads(st_data_t key, st_data_t value, st_data_t result)
{
    thread_data_t *thread = (thread_data_t *) value;
    prof_thread_mark(thread);
    return ST_CONTINUE;
}

static int
mark_methods(st_data_t key, st_data_t value, st_data_t result)
{
    prof_method_t *method = (prof_method_t *) value;
    prof_method_mark(method);
    return ST_CONTINUE;
}

static void
prof_mark(prof_profile_t *profile)
{
    rb_gc_mark(profile->tracepoints);
    st_foreach(profile->threads_tbl, mark_threads, 0);
    st_foreach(profile->exclude_methods_tbl, mark_methods, 0);
}

/* Freeing the profile creates a cascade of freeing.
   It fress the thread table, which frees its methods,
   which frees its call infos. */
static void
prof_free(prof_profile_t *profile)
{
    profile->last_thread_data = NULL;

    threads_table_free(profile->threads_tbl);
    profile->threads_tbl = NULL;

    if (profile->exclude_threads_tbl)
    {
        st_free_table(profile->exclude_threads_tbl);
        profile->exclude_threads_tbl = NULL;
    }

    if (profile->include_threads_tbl)
    {
        st_free_table(profile->include_threads_tbl);
        profile->include_threads_tbl = NULL;
    }

    /* This table owns the excluded sentinels for now. */
    method_table_free(profile->exclude_methods_tbl);
    profile->exclude_methods_tbl = NULL;

    xfree(profile->measurer);
    profile->measurer = NULL;

    xfree(profile);
}

static VALUE
prof_allocate(VALUE klass)
{
    VALUE result;
    prof_profile_t* profile;
    result = Data_Make_Struct(klass, prof_profile_t, prof_mark, prof_free, profile);
    profile->threads_tbl = threads_table_create();
    profile->exclude_threads_tbl = NULL;
    profile->include_threads_tbl = NULL;
    profile->running = Qfalse;
    profile->allow_exceptions = 0;
    profile->exclude_methods_tbl = method_table_create();
    profile->running = Qfalse;
    profile->tracepoints = rb_ary_new();
    return result;
}

static void
prof_exclude_common_methods(VALUE profile)
{
    rb_funcall(profile, rb_intern("exclude_common_methods!"), 0);
}

static int
pop_frames(VALUE key, st_data_t value, st_data_t data)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    prof_profile_t* profile = (prof_profile_t*)data;
    double measurement = prof_measure(profile->measurer);

    if (profile->last_thread_data->fiber != thread_data->fiber)
        switch_thread(profile, thread_data, measurement);

    while (prof_stack_pop(thread_data->stack, measurement));

    return ST_CONTINUE;
}

static void
prof_stop_threads(prof_profile_t* profile)
{
    st_foreach(profile->threads_tbl, pop_frames, (st_data_t)profile);
}

/* call-seq:
   new()
   new(options)

   Returns a new profiler. Possible options for the options hash are:

   measure_mode::     Measure mode. Specifies the profile measure mode.
                      If not specified, defaults to RubyProf::WALL_TIME.
   exclude_threads::  Threads to exclude from the profiling results.
   include_threads::  Focus profiling on only the given threads. This will ignore
                      all other threads.
   merge_fibers::     Whether to merge all fibers under a given thread. This should be
                      used when profiling for a callgrind printer.
   allow_exceptions:: Whether to raise exceptions encountered during profiling,
                      or to suppress all exceptions during profiling
*/
static VALUE
prof_initialize(int argc,  VALUE *argv, VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    VALUE mode_or_options;
    VALUE mode = Qnil;
    VALUE exclude_threads = Qnil;
    VALUE include_threads = Qnil;
    VALUE exclude_common = Qnil;
    VALUE allow_exceptions = Qnil;
    int i;

    switch (rb_scan_args(argc, argv, "02", &mode_or_options, &exclude_threads))
    {
    case 0:
        break;
    case 1:
        if (FIXNUM_P(mode_or_options))
        {
            mode = mode_or_options;
        }
        else
        {
            Check_Type(mode_or_options, T_HASH);
            mode = rb_hash_aref(mode_or_options, ID2SYM(rb_intern("measure_mode")));
            allow_exceptions = rb_hash_aref(mode_or_options, ID2SYM(rb_intern("allow_exceptions")));
            exclude_common = rb_hash_aref(mode_or_options, ID2SYM(rb_intern("exclude_common")));
            exclude_threads = rb_hash_aref(mode_or_options, ID2SYM(rb_intern("exclude_threads")));
            include_threads = rb_hash_aref(mode_or_options, ID2SYM(rb_intern("include_threads")));
        }
        break;
    case 2:
        Check_Type(exclude_threads, T_ARRAY);
        break;
    }

    if (mode == Qnil)
    {
        mode = INT2NUM(MEASURE_WALL_TIME);
    }
    else
    {
        Check_Type(mode, T_FIXNUM);
    }
    profile->measurer = prof_get_measurer(NUM2INT(mode));
    profile->allow_exceptions = allow_exceptions != Qnil && allow_exceptions != Qfalse;

    if (exclude_threads != Qnil)
    {
        Check_Type(exclude_threads, T_ARRAY);
        assert(profile->exclude_threads_tbl == NULL);
        profile->exclude_threads_tbl = threads_table_create();
        for (i = 0; i < RARRAY_LEN(exclude_threads); i++)
        {
            VALUE thread = rb_ary_entry(exclude_threads, i);
            st_insert(profile->exclude_threads_tbl, thread, Qtrue);
        }
    }

    if (include_threads != Qnil)
    {
        Check_Type(include_threads, T_ARRAY);
        assert(profile->include_threads_tbl == NULL);
        profile->include_threads_tbl = threads_table_create();
        for (i = 0; i < RARRAY_LEN(include_threads); i++)
        {
            VALUE thread = rb_ary_entry(include_threads, i);
            st_insert(profile->include_threads_tbl, thread, Qtrue);
        }
    }

    if (RTEST(exclude_common)) {
        prof_exclude_common_methods(self);
    }

    return self;
}

/* call-seq:
   paused? -> boolean

   Returns whether a profile is currently paused.*/
static VALUE
prof_paused(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    return profile->paused;
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
   start -> self

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
    profile->paused = Qfalse;
    profile->last_thread_data = threads_table_insert(profile, rb_fiber_current());

    /* open trace file if environment wants it */
    trace_file_name = getenv("RUBY_PROF_TRACE");
    if (trace_file_name != NULL) 
    {
      if (strcmp(trace_file_name, "stdout") == 0) 
      {
        trace_file = stdout;
      } 
      else if (strcmp(trace_file_name, "stderr") == 0)
      {
        trace_file = stderr;
      }
      else 
      {
        trace_file = fopen(trace_file_name, "w");
      }
    }

    prof_install_hook(self);
    return self;
}

/* call-seq:
   pause -> self

   Pauses collecting profile data. */
static VALUE
prof_pause(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    if (profile->paused == Qfalse)
    {
        profile->paused = Qtrue;
        profile->measurement_at_pause_resume = prof_measure(profile->measurer);
        st_foreach(profile->threads_tbl, pause_thread, (st_data_t) profile);
    }

    return self;
}

/* call-seq:
   resume -> self
   resume(&block) -> self

   Resumes recording profile data.*/
static VALUE
prof_resume(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);
    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    if (profile->paused == Qtrue)
    {
        profile->paused = Qfalse;
        profile->measurement_at_pause_resume = prof_measure(profile->measurer);
        st_foreach(profile->threads_tbl, unpause_thread, (st_data_t) profile);
    }

    return rb_block_given_p() ? rb_ensure(rb_yield, self, prof_pause, self) : self;
}

/* call-seq:
   stop -> self

   Stops collecting profile data.*/
static VALUE
prof_stop(VALUE self)
{
    prof_profile_t* profile = prof_get_profile(self);

    if (profile->running == Qfalse)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was not yet called");
    }

    prof_remove_hook(self);

    /* close trace file if open */
    if (trace_file != NULL)
    {
      if (trace_file !=stderr && trace_file != stdout)
      {
#ifdef _MSC_VER
          _fcloseall();
#else
        fclose(trace_file);
#endif
      }
      trace_file = NULL;
    }

    prof_stop_threads(profile);

    /* Unset the last_thread_data (very important!)
       and the threads table */
    profile->running = profile->paused = Qfalse;
    profile->last_thread_data = NULL;

    return self;
}

/* call-seq:
   threads -> Array of RubyProf::Thread

Returns an array of RubyProf::Thread instances that were executed
while the the program was being run. */
static VALUE
prof_threads(VALUE self)
{
    VALUE result = rb_ary_new();
    prof_profile_t* profile = prof_get_profile(self);
    st_foreach(profile->threads_tbl, collect_threads, result);
    return result;
}

/* call-seq:
   profile {block} -> RubyProf::Result

Profiles the specified block and returns a RubyProf::Result object. */
static VALUE
prof_profile_object(VALUE self)
{
    int result;
    prof_profile_t* profile = prof_get_profile(self);

    if (!rb_block_given_p())
    {
        rb_raise(rb_eArgError, "A block must be provided to the profile method.");
    }

    prof_start(self);
    rb_protect(rb_yield, self, &result);
    self = prof_stop(self);

    if (profile->allow_exceptions && result != 0)
    {
        rb_jump_tag(result);
    }

    return self;

}

/* call-seq:
   profile(&block) -> self
   profile(options, &block) -> self

Profiles the specified block and returns a RubyProf::Profile
object. Arguments are passed to Profile initialize method.
*/
static VALUE
prof_profile_class(int argc,  VALUE *argv, VALUE klass)
{
    return prof_profile_object(rb_class_new_instance(argc, argv, cProfile));
}

static VALUE
prof_exclude_method(VALUE self, VALUE klass, VALUE msym)
{
    prof_profile_t* profile = prof_get_profile(self);

    st_data_t key = method_key(klass, msym);
    prof_method_t *method;

    if (profile->running == Qtrue)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was already called");
    }

    method = method_table_lookup(profile->exclude_methods_tbl, key);

    if (!method)
    {
      method = prof_method_create_excluded(klass, msym);
      method_table_insert(profile->exclude_methods_tbl, method->key, method);
    }

    return self;
}

VALUE prof_profile_dump(VALUE self)
{
    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("threads")), prof_threads(self));
    return result;
}

VALUE prof_profile_load(VALUE self, VALUE data)
{
    prof_profile_t* profile = prof_get_profile(self);

    VALUE threads = rb_hash_aref(data, ID2SYM(rb_intern("threads")));
    for (int i = 0; i < rb_array_len(threads); i++)
    {
        VALUE thread = rb_ary_entry(threads, i);
        thread_data_t* thread_data = DATA_PTR(thread);
        st_insert(profile->threads_tbl, (st_data_t)thread_data->fiber_id, (st_data_t)thread_data);
    }

    return data;
}

void rp_init_profile(void)
{
    mProf = rb_define_module("RubyProf");

    rp_init_allocation();
    rp_init_measure();
    rp_init_method_info();
    rp_init_call_info();
    rp_init_thread();

    cProfile = rb_define_class_under(mProf, "Profile", rb_cObject);
    rb_define_alloc_func (cProfile, prof_allocate);

    rb_define_singleton_method(cProfile, "profile", prof_profile_class, -1);
    rb_define_method(cProfile, "initialize", prof_initialize, -1);
    rb_define_method(cProfile, "start", prof_start, 0);
    rb_define_method(cProfile, "stop", prof_stop, 0);
    rb_define_method(cProfile, "resume", prof_resume, 0);
    rb_define_method(cProfile, "pause", prof_pause, 0);
    rb_define_method(cProfile, "running?", prof_running, 0);
    rb_define_method(cProfile, "paused?", prof_paused, 0);
    rb_define_method(cProfile, "threads", prof_threads, 0);
    rb_define_method(cProfile, "exclude_method!", prof_exclude_method, 2);
    rb_define_method(cProfile, "profile", prof_profile_object, 0);
    rb_define_method(cProfile, "_dump_data", prof_profile_dump, 0);
    rb_define_method(cProfile, "_load_data", prof_profile_load, 1);
}
