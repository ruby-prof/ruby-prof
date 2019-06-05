/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

#define INITIAL_CALL_INFOS_SIZE 2

VALUE cCallInfo;

// Forward declarations
st_table * call_info_table_create(void);

/* =======  prof_call_info_t   ========*/
prof_call_info_t *
prof_call_info_create(prof_method_t *method, prof_method_t *parent)
{
    prof_call_info_t *result = ALLOC(prof_call_info_t);
    result->method = method;
    result->parent = parent;
    result->object = Qnil;

    result->total_time = 0;
    result->self_time = 0;
    result->wait_time = 0;

    result->called = 0;

    result->recursive = 0;
    result->depth = 0;
    result->line = 0;

    return result;
}
static void
prof_call_info_ruby_gc_free(prof_call_info_t *call_info)
{
	/* Has this thread object been accessed by Ruby?  If
	   yes clean it up so to avoid a segmentation fault. */
	if (call_info->object != Qnil)
	{
		RDATA(call_info->object)->data = NULL;
		RDATA(call_info->object)->dfree = NULL;
		RDATA(call_info->object)->dmark = NULL;
    }
	call_info->object = Qnil;
}

void
prof_call_info_mark(prof_call_info_t *call_info)
{
	if (call_info->object != Qnil)
		rb_gc_mark(call_info->object);

    if (call_info->method->object != Qnil)
        rb_gc_mark(call_info->method->object);

    if (call_info->parent && call_info->parent->object != Qnil)
        rb_gc_mark(call_info->parent->object);
}

VALUE
prof_call_info_wrap(prof_call_info_t *call_info)
{
  if (call_info->object == Qnil)
  {
    call_info->object = Data_Wrap_Struct(cCallInfo, prof_call_info_mark, prof_call_info_ruby_gc_free, call_info);
  }
  return call_info->object;
}

static VALUE
prof_call_info_allocate(VALUE klass)
{
    prof_call_info_t* call_info = prof_call_info_create(NULL, NULL);
    call_info->object = prof_call_info_wrap(call_info);
    return call_info->object;
}

prof_call_info_t *
prof_get_call_info(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
	prof_call_info_t* result = DATA_PTR(self);

	if (!result)
	    rb_raise(rb_eRuntimeError, "This RubyProf::CallInfo instance has already been freed, likely because its profile has been freed.");

   return result;
}

/* =======  Call Info Table   ========*/
st_table *
call_info_table_create()
{
  return st_init_table(&type_method_hash);
}

size_t
call_info_table_insert(st_table *table, const prof_method_key_t *key, prof_call_info_t *val)
{
  return st_insert(table, (st_data_t) key, (st_data_t) val);
}

prof_call_info_t *
call_info_table_lookup(st_table *table, const prof_method_key_t *key)
{
    st_data_t val;
    if (st_lookup(table, (st_data_t) key, &val))
    {
      return (prof_call_info_t *) val;
    }
    else
    {
      return NULL;
    }
}

/* =======  RubyProf::CallInfo   ========*/

/* Document-class: RubyProf::CallInfo
RubyProf::CallInfo is a helper class used by RubyProf::MethodInfo
to keep track of which child methods were called and how long
they took to execute. */


/* call-seq:
   parent -> call_info

Returns the call_infos parent call_info object (the method that called this method).*/
static VALUE
prof_call_info_parent(VALUE self)
{
    prof_call_info_t* call_info = prof_get_call_info(self);
    if (call_info->parent)
        return prof_method_wrap(call_info->parent);
    else
        return Qnil;
}

/* call-seq:
   called -> MethodInfo

Returns the target method. */
static VALUE
prof_call_info_target(VALUE self)
{
    prof_call_info_t *call_info = prof_get_call_info(self);
    return prof_method_wrap(call_info->method);
}

/* call-seq:
   called -> int

Returns the total amount of times this method was called. */
static VALUE
prof_call_info_called(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info(self);
    return INT2NUM(result->called);
}

/* call-seq:
   called=n -> n

Sets the call count to n. */
static VALUE
prof_call_info_set_called(VALUE self, VALUE called)
{
    prof_call_info_t *result = prof_get_call_info(self);
    result->called = NUM2INT(called);
    return called;
}

/* call-seq:
   recursive? -> boolean

   Returns the true if this call info is a recursive invocation */
static VALUE
prof_call_info_recursive(VALUE self)
{
  prof_call_info_t *result = prof_get_call_info(self);
  return result->recursive ? Qtrue : Qfalse;
}

/* call-seq:
   depth -> int

   returns the depth of this call info in the call graph */
static VALUE
prof_call_info_depth(VALUE self)
{
  prof_call_info_t *result = prof_get_call_info(self);
  return rb_int_new(result->depth);
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE
prof_call_info_line(VALUE self)
{
  prof_call_info_t *result = prof_get_call_info(self);
  return rb_int_new(result->line);
}

/* call-seq:
   total_time -> float

Returns the total amount of time spent in this method and its children. */
static VALUE
prof_call_info_total_time(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info(self);
    return rb_float_new(result->total_time);
}

/* call-seq:
   add_total_time(call_info) -> nil

adds total time time from call_info to self. */
static VALUE
prof_call_info_add_total_time(VALUE self, VALUE other)
{
    prof_call_info_t *result = prof_get_call_info(self);
    prof_call_info_t *other_info = prof_get_call_info(other);

    result->total_time += other_info->total_time;
    return Qnil;
}

/* call-seq:
   self_time -> float

Returns the total amount of time spent in this method. */
static VALUE
prof_call_info_self_time(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info(self);

    return rb_float_new(result->self_time);
}

/* call-seq:
   add_self_time(call_info) -> nil

adds self time from call_info to self. */
static VALUE
prof_call_info_add_self_time(VALUE self, VALUE other)
{
    prof_call_info_t *result = prof_get_call_info(self);
    prof_call_info_t *other_info = prof_get_call_info(other);

    result->self_time += other_info->self_time;
    return Qnil;
}

/* call-seq:
   wait_time -> float

Returns the total amount of time this method waited for other threads. */
static VALUE
prof_call_info_wait_time(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info(self);

    return rb_float_new(result->wait_time);
}

/* call-seq:
   add_wait_time(call_info) -> nil

adds wait time from call_info to self. */

static VALUE
prof_call_info_add_wait_time(VALUE self, VALUE other)
{
    prof_call_info_t *result = prof_get_call_info(self);
    prof_call_info_t *other_info = prof_get_call_info(other);

    result->wait_time += other_info->wait_time;
    return Qnil;
}

static VALUE
prof_call_info_dump(VALUE self)
{
    prof_call_info_t* call_info_data = prof_get_call_info(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("total_time")), rb_float_new(call_info_data->total_time));
    rb_hash_aset(result, ID2SYM(rb_intern("self_time")), rb_float_new(call_info_data->self_time));
    rb_hash_aset(result, ID2SYM(rb_intern("wait_time")), rb_float_new(call_info_data->wait_time));

    rb_hash_aset(result, ID2SYM(rb_intern("called")), INT2FIX(call_info_data->called));

    rb_hash_aset(result, ID2SYM(rb_intern("recursive")), INT2FIX(call_info_data->recursive));
    rb_hash_aset(result, ID2SYM(rb_intern("depth")), INT2FIX(call_info_data->depth));
    rb_hash_aset(result, ID2SYM(rb_intern("line")), INT2FIX(call_info_data->line));

    rb_hash_aset(result, ID2SYM(rb_intern("parent")), prof_call_info_parent(self));
    rb_hash_aset(result, ID2SYM(rb_intern("target")), prof_call_info_target(self));

    return result;
}

static VALUE
prof_call_info_load(VALUE self, VALUE data)
{
    prof_call_info_t* call_info = prof_get_call_info(self);

    call_info->total_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("total_time"))));
    call_info->self_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("self_time"))));
    call_info->wait_time = rb_num2dbl(rb_hash_aref(data, ID2SYM(rb_intern("wait_time"))));

    call_info->called = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("called"))));

    call_info->recursive = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("recursive"))));
    call_info->depth = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("depth"))));
    call_info->line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("line"))));

    VALUE parent = rb_hash_aref(data, ID2SYM(rb_intern("parent")));
    if (parent != Qnil)
        call_info->parent = prof_method_get(parent);

    VALUE target = rb_hash_aref(data, ID2SYM(rb_intern("target")));
    call_info->method = prof_method_get(target);

    return data;
}

void rp_init_call_info()
{
    /* CallInfo */
    cCallInfo = rb_define_class_under(mProf, "CallInfo", rb_cObject);
    rb_undef_method(CLASS_OF(cCallInfo), "new");
    rb_define_alloc_func(cCallInfo, prof_call_info_allocate);

    rb_define_method(cCallInfo, "parent", prof_call_info_parent, 0);
    rb_define_method(cCallInfo, "target", prof_call_info_target, 0);

    rb_define_method(cCallInfo, "called", prof_call_info_called, 0);
    rb_define_method(cCallInfo, "called=", prof_call_info_set_called, 1);
    rb_define_method(cCallInfo, "total_time", prof_call_info_total_time, 0);
    rb_define_method(cCallInfo, "add_total_time", prof_call_info_add_total_time, 1);
    rb_define_method(cCallInfo, "self_time", prof_call_info_self_time, 0);
    rb_define_method(cCallInfo, "add_self_time", prof_call_info_add_self_time, 1);
    rb_define_method(cCallInfo, "wait_time", prof_call_info_wait_time, 0);
    rb_define_method(cCallInfo, "add_wait_time", prof_call_info_add_wait_time, 1);

    rb_define_method(cCallInfo, "recursive?", prof_call_info_recursive, 0);
    rb_define_method(cCallInfo, "depth", prof_call_info_depth, 0);
    rb_define_method(cCallInfo, "line", prof_call_info_line, 0);

    rb_define_method(cCallInfo, "_dump_data", prof_call_info_dump, 0);
    rb_define_method(cCallInfo, "_load_data", prof_call_info_load, 1);
}
