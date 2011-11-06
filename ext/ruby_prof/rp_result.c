/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h" 

VALUE cResult;


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

void rp_init_result()
{
    cResult = rb_define_class_under(mProf, "Result", rb_cObject);
    rb_undef_method(CLASS_OF(cMethodInfo), "new");
    rb_define_method(cResult, "threads", prof_result_threads, 0);
}
