/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

VALUE cRpThread;

/* ======   thread_data_t  ====== */
thread_data_t*
thread_data_create()
{
    thread_data_t* result = ALLOC(thread_data_t);
    result->stack = stack_create();
    result->method_table = method_table_create();
	result->top = NULL;
	result->object = Qnil;
    return result;
}

void
thread_data_free(thread_data_t* thread_data)
{
    thread_data->top = NULL;
    method_table_free(thread_data->method_table);
    stack_free(thread_data->stack);

	/* Has this thread object been accessed by Ruby?  If
	   yes clean it up so to avoid a segmentation fault. */
	if (thread_data->object != Qnil)
	{
		RDATA(thread_data->object)->data = NULL;
		RDATA(thread_data->object)->dfree = NULL;
		RDATA(thread_data->object)->dmark = NULL;
    }
	thread_data->object = Qnil;
    thread_data->thread_id = Qnil;

	xfree(thread_data);
}

static int
mark_methods(st_data_t key, st_data_t value, st_data_t result)
{
    prof_method_t *method = (prof_method_t *) value;
    prof_method_mark(method);
    return ST_CONTINUE;
}

VALUE
prof_thread_mark(thread_data_t *thread)
{
	if (thread->object != Qnil)
		rb_gc_mark(thread->object);
	
	prof_method_mark(thread->top);
	st_foreach(thread->method_table, mark_methods, NULL);
}

VALUE
prof_thread_wrap(thread_data_t *thread)
{
  if (thread->object == Qnil)
  {
    thread->object = Data_Wrap_Struct(cRpThread, prof_thread_mark, NULL, thread);
  }
  return thread->object;
}

static thread_data_t*
prof_get_thread(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
	thread_data_t* result = DATA_PTR(self);
	if (!result)
	    rb_raise(rb_eRuntimeError, "This RubyProf::Thread instance has already been freed, likely because its profile has been freed.");

   return result;
}

/* ======   Thread Table  ====== */
/* The thread table is hash keyed on ruby thread_id that stores instances
   of thread_data_t. */

st_table *
threads_table_create()
{
    return st_init_numtable();
}

int
thread_table_free_iterator(st_data_t key, st_data_t value, st_data_t dummy)
{
    thread_data_free((thread_data_t*)value);
    return ST_CONTINUE;
}

void
threads_table_free(st_table *table)
{
    st_foreach(table, thread_table_free_iterator, 0);
    st_free_table(table);
}

size_t
threads_table_insert(prof_profile_t* profile, VALUE thread, thread_data_t *thread_data)
{
    /* Its too slow to key on the real thread id so just typecast thread instead. */
    return st_insert(profile->threads_tbl, (st_data_t) thread, (st_data_t) thread_data);
}

thread_data_t *
threads_table_lookup(prof_profile_t* profile, VALUE thread_id)
{
    thread_data_t* result;
    st_data_t val;

    /* Its too slow to key on the real thread id so just typecast thread instead. */
    if (st_lookup(profile->threads_tbl, (st_data_t) thread_id, &val))
    {
      result = (thread_data_t *) val;
    }
    else
    {
        result = thread_data_create();
        result->thread_id = thread_id;

        /* Insert the table */
        threads_table_insert(profile, thread_id, result);
    }
    return result;
}

thread_data_t *
switch_thread(void* prof, VALUE thread_id)
{
    prof_profile_t* profile = (prof_profile_t*)prof;
    double measurement = profile->measurer->measure();

    /* Get new thread information. */
    thread_data_t *thread_data = threads_table_lookup(profile, thread_id);

    /* Get current frame for this thread */
    prof_frame_t *frame = stack_peek(thread_data->stack);

    /* Update the time this thread waited for another thread */
    if (frame)
    {
        frame->wait_time += measurement - frame->switch_time;
        frame->switch_time = measurement;
    }

    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (profile->last_thread_data)
    {
       prof_frame_t *last_frame = stack_peek(profile->last_thread_data->stack);
       if (last_frame)
         last_frame->switch_time = measurement;
    }

    profile->last_thread_data = thread_data;
    return thread_data;
}

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


/* call-seq:
   id -> number

Returns the id of this thread. */
static VALUE
prof_thread_id(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
	return thread->thread_id;
}

/* call-seq:
   methods -> Array of MethodInfo

Returns an array of methods that were called from this
thread during program execution. */
static VALUE
prof_thread_methods(VALUE self)
{
	VALUE methods = rb_ary_new();
    thread_data_t* thread = prof_get_thread(self);
    st_table* method_table = thread->method_table;
    st_foreach(method_table, collect_methods, methods);
	return methods;
}

/* call-seq:
   method -> MethodInfo

Returns the top level method for this thread (ie, the starting
method). */
static VALUE
prof_thread_top_method(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
	return  prof_method_wrap(thread->top);
}

void rp_init_thread()
{
    cRpThread = rb_define_class_under(mProf, "Thread", rb_cObject);
    rb_undef_method(CLASS_OF(cRpThread), "new");

    rb_define_method(cRpThread, "id", prof_thread_id, 0);
    rb_define_method(cRpThread, "methods", prof_thread_methods, 0);
    rb_define_method(cRpThread, "top_method", prof_thread_top_method, 0);
}
