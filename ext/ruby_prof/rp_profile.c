/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h" 

VALUE cResult;

static int
collect_methods(st_data_t key, st_data_t value, st_data_t result)
{
    /* Called for each method stored in a thread's method table.
       We want to store the method info information into an array.*/
    VALUE methods = (VALUE) result;
    prof_method_t *method = (prof_method_t *) value;
    rb_ary_push(methods, prof_method_wrap(method));

    /* Wrap call info objects */
    prof_call_infos_wrap(method->call_infos);

    return ST_CONTINUE;
}

static int
collect_threads(st_data_t key, st_data_t value, st_data_t result)
{
    /* Although threads are keyed on an id, that is actually a
       pointer to the VALUE object of the thread.  So its bogus.
       However, in thread_data is the real thread id stored
       as an int. */
    thread_data_t* thread_data = (thread_data_t*) value;
    VALUE threads_hash = (VALUE) result;

    VALUE methods = rb_ary_new();

    /* Now collect an array of all the called methods */
    st_table* method_table = thread_data->method_table;
    st_foreach(method_table, collect_methods, methods);

    /* Store the results in the threads hash keyed on the thread id. */
    rb_hash_aset(threads_hash, thread_data->thread_id, methods);

    return ST_CONTINUE;
}

/* ========  ProfResult ============== */

/* Document-class: RubyProf::Result
The RubyProf::Result class is used to store the results of a
profiling run.  And instace of the class is returned from
the methods RubyProf#stop and RubyProf#profile.

RubyProf::Result has one field, called threads, which is a hash
table keyed on thread ID.  For each thread id, the hash table
stores another hash table that contains profiling information
for each method called during the threads execution.  That
hash table is keyed on method name and contains
RubyProf::MethodInfo objects. */

static void
prof_result_mark(prof_result_t *prof_result)
{
    VALUE threads = prof_result->threads;
    rb_gc_mark(threads);
}

static void
prof_result_free(prof_result_t *prof_result)
{
    prof_result->threads = Qnil;
    xfree(prof_result);
}

VALUE
prof_result_new(st_table* threads_tbl)
{
    prof_result_t *prof_result = ALLOC(prof_result_t);

    /* Wrap threads in Ruby regular Ruby hash table. */
    prof_result->threads = rb_hash_new();
    st_foreach(threads_tbl, collect_threads, prof_result->threads);

    return Data_Wrap_Struct(cResult, prof_result_mark, prof_result_free, prof_result);
}


static prof_result_t *
get_prof_result(VALUE obj)
{
    if (BUILTIN_TYPE(obj) != T_DATA ||
      RDATA(obj)->dfree != (RUBY_DATA_FUNC) prof_result_free)
    {
        /* Should never happen */
      rb_raise(rb_eTypeError, "wrong result object (%d %d) ", BUILTIN_TYPE(obj) != T_DATA, RDATA(obj)->dfree != (RUBY_DATA_FUNC) prof_result_free);
    }
    return (prof_result_t *) DATA_PTR(obj);
}

/* call-seq:
   threads -> Hash

Returns a hash table keyed on thread ID.  For each thread id,
the hash table stores another hash table that contains profiling
information for each method called during the threads execution.
That hash table is keyed on method name and contains
RubyProf::MethodInfo objects. */
static VALUE
prof_result_threads(VALUE self)
{
    prof_result_t *prof_result = get_prof_result(self);
    return prof_result->threads;
}

void rp_init_profile()
{
    cProfile = rb_define_class_under(mProf, "Profile", rb_cObject);
    rb_define_method(cProfile, "start", prof_start, 0);
    rb_define_method(cProfile, "stop", prof_stop, 0);
    rb_define_method(cProfile, "resume", prof_resume, 0);
    rb_define_method(cProfile, "pause", prof_pause, 0);
    rb_define_method(cProfile, "running?", prof_running, 0);
    rb_define_method(cProfile, "profile", prof_profile, 0);
}
