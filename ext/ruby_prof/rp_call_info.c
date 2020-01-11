/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_info.h"

#define INITIAL_CALL_INFOS_SIZE 2

VALUE cRpCallnfo;

/* =======  prof_call_info_t   ========*/
prof_call_info_t* prof_call_info_create(prof_method_t* method, prof_call_info_t* parent, VALUE source_file, int source_line)
{
    prof_call_info_t* result = ALLOC(prof_call_info_t);
    result->method = method;
    result->parent = parent;
    result->children = method_table_create();
    result->object = Qnil;
    result->measurement = prof_measurement_create();

    result->visits = 0;

    result->depth = 0;
    result->source_line = source_line;
    result->source_file = source_file;

    return result;
}

prof_call_info_t* prof_call_info_copy(prof_call_info_t* other)
{
    prof_call_info_t* result = ALLOC(prof_call_info_t);
    result->children = method_table_create();
    result->object = Qnil;
    result->visits = 0;

    result->method = other->method;
    result->parent = other->parent;
    result->depth = other->depth;
    result->source_line = other->source_line;
    result->source_file = other->source_file;

    result->measurement = prof_measurement_create();
    result->measurement->called = other->measurement->called;
    result->measurement->total_time = other->measurement->total_time;
    result->measurement->self_time = other->measurement->self_time;
    result->measurement->wait_time = other->measurement->wait_time;
    result->measurement->object = Qnil;

    return result;
}

void prof_call_info_merge(prof_call_info_t* result, prof_call_info_t* other)
{
    result->measurement->called += other->measurement->called;
    result->measurement->total_time += other->measurement->total_time;
    result->measurement->self_time += other->measurement->self_time;
    result->measurement->wait_time += other->measurement->wait_time;
}

static int prof_call_info_collect_call_infos(st_data_t key, st_data_t value, st_data_t result)
{
    prof_call_info_t* call_info = (prof_call_info_t*)value;
    VALUE arr = (VALUE)result;
    rb_ary_push(arr, prof_call_info_wrap(call_info));
    return ST_CONTINUE;
}

static int prof_call_info_mark_children(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_info_t* call_info = (prof_call_info_t*)value;
    prof_call_info_mark(call_info);
    return ST_CONTINUE;
}

static void prof_call_info_ruby_gc_free(void* data)
{
    prof_call_info_t* call_info = (prof_call_info_t*)data;

    /* Has this call info object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (call_info->object != Qnil)
    {
        RDATA(call_info->object)->dmark = NULL;
        RDATA(call_info->object)->dfree = NULL;
        RDATA(call_info->object)->data = NULL;
        call_info->object = Qnil;
    }
}

void prof_call_info_free(prof_call_info_t* call_info)
{
    prof_measurement_free(call_info->measurement);
    prof_call_info_ruby_gc_free(call_info);

    /* Note we do not free our parent or children. Its up to prof_method_t objects to call free on the
       call infos they manage. */
    st_free_table(call_info->children);
    xfree(call_info);
}

size_t prof_call_info_size(const void* data)
{
    return sizeof(prof_call_info_t);
}

void prof_call_info_mark(void* data)
{
    prof_call_info_t* call_info = (prof_call_info_t*)data;

    if (call_info->source_file != Qnil)
        rb_gc_mark(call_info->source_file);

    if (call_info->object != Qnil)
        rb_gc_mark(call_info->object);

    if (call_info->method && call_info->method->object != Qnil)
        rb_gc_mark(call_info->method->object);

    if (call_info->parent && call_info->parent->object != Qnil)
        rb_gc_mark(call_info->parent->object);

    st_foreach(call_info->children, prof_call_info_mark_children, 0);
    prof_measurement_mark(call_info->measurement);
}

VALUE
prof_call_info_wrap(prof_call_info_t* call_info)
{
    if (call_info->object == Qnil)
    {
        call_info->object = Data_Wrap_Struct(cRpCallnfo, prof_call_info_mark, prof_call_info_ruby_gc_free, call_info);
    }
    return call_info->object;
}

static VALUE prof_call_info_allocate(VALUE klass)
{
    prof_call_info_t* call_info = prof_call_info_create(NULL, NULL, Qnil, 0);
    call_info->object = prof_call_info_wrap(call_info);
    return call_info->object;
}

prof_call_info_t* prof_get_call_info(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_call_info_t* result = DATA_PTR(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::CallInfo instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* =======  Call Info Table   ========*/
st_table* call_info_table_create()
{
    return st_init_numtable();
}

size_t
call_info_table_insert(st_table* table, st_data_t key, prof_call_info_t* val)
{
    return st_insert(table, (st_data_t)key, (st_data_t)val);
}

prof_call_info_t* call_info_table_lookup(st_table* table, st_data_t key)
{
    st_data_t val;
    if (st_lookup(table, (st_data_t)key, &val))
    {
        return (prof_call_info_t*)val;
    }
    else
    {
        return NULL;
    }
}

/* =======  RubyProf::CallInfo   ========*/

/* call-seq:
   parent -> call_info

Returns the call_infos parent call_info object (the method that called this method).*/
static VALUE prof_call_info_parent(VALUE self)
{
    prof_call_info_t* call_info = prof_get_call_info(self);
    if (call_info->parent)
        return prof_call_info_wrap(call_info->parent);
    else
        return Qnil;
}

/* call-seq:
   callees -> array

Returns an array of call info objects that this method called (ie, children).*/
static VALUE prof_call_info_children(VALUE self)
{
    prof_call_info_t* call_info = prof_get_call_info(self);
    VALUE result = rb_ary_new();
    st_foreach(call_info->children, prof_call_info_collect_call_infos, result);
    return result;
}

/* call-seq:
   called -> MethodInfo

Returns the target method. */
static VALUE prof_call_info_target(VALUE self)
{
    prof_call_info_t* call_info = prof_get_call_info(self);
    return prof_method_wrap(call_info->method);
}

/* call-seq:
   called -> Measurement

Returns the measurement associated with this call_info. */
static VALUE prof_call_info_measurement(VALUE self)
{
    prof_call_info_t* call_info = prof_get_call_info(self);
    return prof_measurement_wrap(call_info->measurement);
}

/* call-seq:
   depth -> int

   returns the depth of this call info in the call graph */
static VALUE prof_call_info_depth(VALUE self)
{
    prof_call_info_t* result = prof_get_call_info(self);
    return rb_int_new(result->depth);
}

/* call-seq:
   source_file => string

return the source file of the method
*/
static VALUE prof_call_info_source_file(VALUE self)
{
    prof_call_info_t* result = prof_get_call_info(self);
    return result->source_file;
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE prof_call_info_line(VALUE self)
{
    prof_call_info_t* result = prof_get_call_info(self);
    return INT2FIX(result->source_line);
}

/* :nodoc: */
static VALUE prof_call_info_dump(VALUE self)
{
    prof_call_info_t* call_info_data = prof_get_call_info(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("measurement")), prof_measurement_wrap(call_info_data->measurement));

    rb_hash_aset(result, ID2SYM(rb_intern("depth")), INT2FIX(call_info_data->depth));
    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), call_info_data->source_file);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(call_info_data->source_line));

    rb_hash_aset(result, ID2SYM(rb_intern("parent")), prof_call_info_parent(self));
    rb_hash_aset(result, ID2SYM(rb_intern("children")), prof_call_info_children(self));
    rb_hash_aset(result, ID2SYM(rb_intern("target")), prof_call_info_target(self));

    return result;
}

/* :nodoc: */
static VALUE prof_call_info_load(VALUE self, VALUE data)
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
        call_info->parent = prof_get_call_info(parent);

    VALUE callees = rb_hash_aref(data, ID2SYM(rb_intern("children")));
    for (int i = 0; i < rb_array_len(callees); i++)
    {
        VALUE call_info_object = rb_ary_entry(callees, i);
        prof_call_info_t* call_info_data = prof_get_call_info(call_info_object);

        st_data_t key = call_info_data->method ? call_info_data->method->key : method_key(Qnil, 0);
        call_info_table_insert(call_info->children, key, call_info_data);
    }

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
    rb_define_method(cRpCallnfo, "children", prof_call_info_children, 0);
    rb_define_method(cRpCallnfo, "target", prof_call_info_target, 0);
    rb_define_method(cRpCallnfo, "measurement", prof_call_info_measurement, 0);

    rb_define_method(cRpCallnfo, "depth", prof_call_info_depth, 0);
    rb_define_method(cRpCallnfo, "source_file", prof_call_info_source_file, 0);
    rb_define_method(cRpCallnfo, "line", prof_call_info_line, 0);

    rb_define_method(cRpCallnfo, "_dump_data", prof_call_info_dump, 0);
    rb_define_method(cRpCallnfo, "_load_data", prof_call_info_load, 1);
}
