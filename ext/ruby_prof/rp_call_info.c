/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_info.h"

#define INITIAL_CALL_INFOS_SIZE 2

VALUE cRpCallnfo;

/* =======  prof_call_info_t   ========*/
prof_call_info_t *
prof_call_info_create(prof_method_t *method, prof_method_t *parent, VALUE source_file, int source_line)
{
    prof_call_info_t *result = ALLOC(prof_call_info_t);
    result->method = method;
    result->parent = parent;
    result->object = Qnil;
    result->measurement = prof_measurement_create();

    result->visits = 0;

    result->depth = 0;
    result->source_line = source_line;
    result->source_file = source_file;

    return result;
}

static void
prof_call_info_ruby_gc_free(void *data)
{
    prof_call_info_t *call_info = (prof_call_info_t*)data;

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
prof_call_info_free(prof_call_info_t *call_info)
{
    prof_call_info_ruby_gc_free(call_info);
    xfree(call_info);
}

size_t
prof_call_info_size(const void *data)
{
    return sizeof(prof_call_info_t);
}

void
prof_call_info_mark(void *data)
{
    prof_call_info_t *call_info = (prof_call_info_t*)data;

    if (call_info->source_file != Qnil)
        rb_gc_mark(call_info->source_file);

	if (call_info->object != Qnil)
		rb_gc_mark(call_info->object);

    if (call_info->method && call_info->method->object != Qnil)
        rb_gc_mark(call_info->method->object);

    if (call_info->parent && call_info->parent->object != Qnil)
        rb_gc_mark(call_info->parent->object);

    prof_measurement_mark(call_info->measurement);
}

static const rb_data_type_t call_info_type =
{
    .wrap_struct_name = "CallInfo",
    .function =
    {
        .dmark = prof_call_info_mark,
        .dfree = prof_call_info_ruby_gc_free,
        .dsize = prof_call_info_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE
prof_call_info_wrap(prof_call_info_t *call_info)
{
    if (call_info->object == Qnil)
    {
        call_info->object =  TypedData_Wrap_Struct(cRpCallnfo, &call_info_type, call_info);
    }
    return call_info->object;
}

static VALUE
prof_call_info_allocate(VALUE klass)
{
    prof_call_info_t* call_info = prof_call_info_create(NULL, NULL, Qnil, 0);
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
    return st_init_numtable();
}

size_t
call_info_table_insert(st_table *table, st_data_t key, prof_call_info_t *val)
{
  return st_insert(table, (st_data_t) key, (st_data_t) val);
}

prof_call_info_t *
call_info_table_lookup(st_table *table, st_data_t key)
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
   called -> Measurement

Returns the measurement associated with this call_info. */
static VALUE
prof_call_info_measurement(VALUE self)
{
    prof_call_info_t* call_info = prof_get_call_info(self);
    return prof_measurement_wrap(call_info->measurement);
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
   source_file => string

return the source file of the method
*/
static VALUE
prof_call_info_source_file(VALUE self)
{
    prof_call_info_t* result = prof_get_call_info(self);
    return result->source_file;
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE
prof_call_info_line(VALUE self)
{
  prof_call_info_t *result = prof_get_call_info(self);
  return INT2FIX(result->source_line);
}

static VALUE
prof_call_info_dump(VALUE self)
{
    prof_call_info_t* call_info_data = prof_get_call_info(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("measurement")), prof_measurement_wrap(call_info_data->measurement));

    rb_hash_aset(result, ID2SYM(rb_intern("depth")), INT2FIX(call_info_data->depth));
    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), call_info_data->source_file);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(call_info_data->source_line));

    rb_hash_aset(result, ID2SYM(rb_intern("parent")), prof_call_info_parent(self));
    rb_hash_aset(result, ID2SYM(rb_intern("target")), prof_call_info_target(self));

    return result;
}

static VALUE
prof_call_info_load(VALUE self, VALUE data)
{
	VALUE target = Qnil;
	VALUE parent = Qnil;
	prof_call_info_t* call_info = prof_get_call_info(self);
    call_info->object = self;

    VALUE measurement = rb_hash_aref(data, ID2SYM(rb_intern("measurement")));
    call_info->measurement = prof_get_measurement(measurement);

    call_info->depth = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("depth"))));
    call_info->source_file = rb_hash_aref(data, ID2SYM(rb_intern("source_file")));
    call_info->source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("source_line"))));

    parent = rb_hash_aref(data, ID2SYM(rb_intern("parent")));
    if (parent != Qnil)
        call_info->parent = prof_method_get(parent);

    target = rb_hash_aref(data, ID2SYM(rb_intern("target")));
    call_info->method = prof_method_get(target);

    return data;
}

void rp_init_call_info()
{
    /* CallInfo */
    cRpCallnfo = rb_define_class_under(mProf, "CallInfo", rb_cData);
    rb_undef_method(CLASS_OF(cRpCallnfo), "new");
    rb_define_alloc_func(cRpCallnfo, prof_call_info_allocate);

    rb_define_method(cRpCallnfo, "parent", prof_call_info_parent, 0);
    rb_define_method(cRpCallnfo, "target", prof_call_info_target, 0);
    rb_define_method(cRpCallnfo, "measurement", prof_call_info_measurement, 0);

    rb_define_method(cRpCallnfo, "depth", prof_call_info_depth, 0);
    rb_define_method(cRpCallnfo, "source_file", prof_call_info_source_file, 0);
    rb_define_method(cRpCallnfo, "line", prof_call_info_line, 0);

    rb_define_method(cRpCallnfo, "_dump_data", prof_call_info_dump, 0);
    rb_define_method(cRpCallnfo, "_load_data", prof_call_info_load, 1);
}
