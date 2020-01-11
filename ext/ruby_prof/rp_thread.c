/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

   /* Document-class: RubyProf::Thread

   The Thread class contains profile results for a single fiber (note a Ruby thread can run multiple fibers).
   You cannot create an instance of RubyProf::Thread, instead you access it from a RubyProf::Profile object.

     profile = RubyProf::Profile.profile do
                 ...
               end

     profile.threads.each do |thread|
       thread.root_methods.sort.each do |method|
         puts method.total_time
       end
     end
   */

#include "rp_thread.h"
#include "rp_profile.h"

VALUE cRpThread;

/* ======   thread_data_t  ====== */
thread_data_t* thread_data_create(void)
{
    thread_data_t* result = ALLOC(thread_data_t);
    result->stack = prof_stack_create();
    result->method_table = method_table_create();
    result->object = Qnil;
    result->methods = Qnil;
    result->fiber_id = Qnil;
    result->thread_id = Qnil;
    result->trace = true;
    result->fiber = Qnil;
    return result;
}

static void prof_thread_free(thread_data_t* thread_data)
{
    /* Has this method object been accessed by Ruby?  If
       yes then set its data to nil to avoid a segmentation fault on the next mark and sweep. */
    if (thread_data->object != Qnil)
    {
        RDATA(thread_data->object)->dmark = NULL;
        RDATA(thread_data->object)->dfree = NULL;
        RDATA(thread_data->object)->data = NULL;
    }

    method_table_free(thread_data->method_table);
    prof_call_tree_free(thread_data->call_tree);
    prof_stack_free(thread_data->stack);

    xfree(thread_data);
}

static int mark_methods(st_data_t key, st_data_t value, st_data_t result)
{
    prof_method_t* method = (prof_method_t*)value;
    prof_method_mark(method);
    return ST_CONTINUE;
}

size_t prof_thread_size(const void* data)
{
    return sizeof(prof_call_tree_t);
}

void prof_thread_mark(void* data)
{
    thread_data_t* thread = (thread_data_t*)data;

    if (thread->methods != Qnil)
        rb_gc_mark(thread->methods);

    if (thread->fiber_id != Qnil)
        rb_gc_mark(thread->fiber_id);

    if (thread->thread_id != Qnil)
        rb_gc_mark(thread->thread_id);

    st_foreach(thread->method_table, mark_methods, 0);
}


VALUE prof_thread_wrap(thread_data_t* thread)
{
    if (thread->object == Qnil)
    {
        thread->object = Data_Wrap_Struct(cRpThread, prof_thread_mark, NULL, thread);
    }
    return thread->object;
}

static VALUE prof_thread_allocate(VALUE klass)
{
    thread_data_t* thread_data = thread_data_create();
    thread_data->object = prof_thread_wrap(thread_data);
    return thread_data->object;
}

static thread_data_t* prof_get_thread(VALUE self)
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

st_table* threads_table_create()
{
    return st_init_numtable();
}

static int thread_table_free_iterator(st_data_t key, st_data_t value, st_data_t dummy)
{
    prof_thread_free((thread_data_t*)value);
    return ST_CONTINUE;
}

void threads_table_free(st_table* table)
{
    st_foreach(table, thread_table_free_iterator, 0);
    st_free_table(table);
}

thread_data_t* threads_table_lookup(void* prof, VALUE fiber)
{
    prof_profile_t* profile = prof;
    thread_data_t* result = NULL;
    st_data_t val;

    if (st_lookup(profile->threads_tbl, fiber, &val))
    {
        result = (thread_data_t*)val;
    }

    return result;
}

thread_data_t* threads_table_insert(void* prof, VALUE fiber)
{
    prof_profile_t* profile = prof;
    thread_data_t* result = thread_data_create();
    VALUE thread = rb_thread_current();

    result->fiber = fiber;
    result->fiber_id = rb_obj_id(fiber);
    result->thread_id = rb_obj_id(thread);
    st_insert(profile->threads_tbl, (st_data_t)fiber, (st_data_t)result);

    // Are we tracing this thread?
    if (profile->include_threads_tbl && !st_lookup(profile->include_threads_tbl, thread, 0))
    {
        result->trace = false;
    }
    else if (profile->exclude_threads_tbl && st_lookup(profile->exclude_threads_tbl, thread, 0))
    {
        result->trace = false;
    }
    else
    {
        result->trace = true;
    }

    return result;
}

void switch_thread(void* prof, thread_data_t* thread_data, double measurement)
{
    prof_profile_t* profile = prof;

    /* Get current frame for this thread */
    prof_frame_t* frame = thread_data->stack->ptr;
    frame->wait_time += measurement - frame->switch_time;
    frame->switch_time = measurement;

    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (profile->last_thread_data)
    {
        prof_frame_t* last_frame = profile->last_thread_data->stack->ptr;
        if (last_frame)
            last_frame->switch_time = measurement;
    }

    profile->last_thread_data = thread_data;
}

int pause_thread(st_data_t key, st_data_t value, st_data_t data)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    prof_profile_t* profile = (prof_profile_t*)data;

    prof_frame_t* frame = thread_data->stack->ptr;
    prof_frame_pause(frame, profile->measurement_at_pause_resume);

    return ST_CONTINUE;
}

int unpause_thread(st_data_t key, st_data_t value, st_data_t data)
{
    thread_data_t* thread_data = (thread_data_t*)value;
    prof_profile_t* profile = (prof_profile_t*)data;

    prof_frame_t* frame = thread_data->stack->ptr;
    prof_frame_unpause(frame, profile->measurement_at_pause_resume);

    return ST_CONTINUE;
}

static int collect_methods(st_data_t key, st_data_t value, st_data_t result)
{
    /* Called for each method stored in a thread's method table.
       We want to store the method info information into an array.*/
    VALUE methods = (VALUE)result;
    prof_method_t* method = (prof_method_t*)value;

    if (!method->excluded)
    {
        rb_ary_push(methods, prof_method_wrap(method));
    }

    return ST_CONTINUE;
}

/* call-seq:
   id -> number

Returns the thread id of this thread. */
static VALUE prof_thread_id(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    return thread->thread_id;
}

/* call-seq:
   fiber_id -> number

Returns the fiber id of this thread. */
static VALUE prof_fiber_id(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    return thread->fiber_id;
}

/* call-seq:
   call_tree -> CallTree

Returns the root of the call tree. */
static VALUE prof_call_tree(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    return prof_call_tree_wrap(thread->call_tree);
}

/* call-seq:
   methods -> [RubyProf::MethodInfo]

Returns an array of methods that were called from this
thread during program execution. */
static VALUE prof_thread_methods(VALUE self)
{
    thread_data_t* thread = prof_get_thread(self);
    if (thread->methods == Qnil)
    {
        thread->methods = rb_ary_new();
        st_foreach(thread->method_table, collect_methods, thread->methods);
    }
    return thread->methods;
}

/* :nodoc: */
static VALUE prof_thread_dump(VALUE self)
{
    thread_data_t* thread_data = DATA_PTR(self);

    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("fiber_id")), thread_data->fiber_id);
    rb_hash_aset(result, ID2SYM(rb_intern("methods")), prof_thread_methods(self));

    return result;
}

/* :nodoc: */
static VALUE prof_thread_load(VALUE self, VALUE data)
{
    thread_data_t* thread_data = DATA_PTR(self);
    thread_data->object = self;

    thread_data->fiber_id = rb_hash_aref(data, ID2SYM(rb_intern("fiber_id")));
    VALUE methods = rb_hash_aref(data, ID2SYM(rb_intern("methods")));

    for (int i = 0; i < rb_array_len(methods); i++)
    {
        VALUE method = rb_ary_entry(methods, i);
        prof_method_t* method_data = DATA_PTR(method);
        method_table_insert(thread_data->method_table, method_data->key, method_data);
    }

    return data;
}

void rp_init_thread(void)
{
    cRpThread = rb_define_class_under(mProf, "Thread", rb_cData);
    rb_undef_method(CLASS_OF(cRpThread), "new");
    rb_define_alloc_func(cRpThread, prof_thread_allocate);

    rb_define_method(cRpThread, "id", prof_thread_id, 0);
    rb_define_method(cRpThread, "call_tree", prof_call_tree, 0);
    rb_define_method(cRpThread, "fiber_id", prof_fiber_id, 0);
    rb_define_method(cRpThread, "methods", prof_thread_methods, 0);
    rb_define_method(cRpThread, "_dump_data", prof_thread_dump, 0);
    rb_define_method(cRpThread, "_load_data", prof_thread_load, 1);
}
