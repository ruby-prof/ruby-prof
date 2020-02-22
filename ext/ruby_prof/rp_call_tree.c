/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_tree.h"

#define INITIAL_CALL_TREES_SIZE 2

VALUE cRpCallTree;

/* =======  prof_call_tree_t   ========*/
prof_call_tree_t* prof_call_tree_create(prof_method_t* method, prof_call_tree_t* parent, VALUE source_file, int source_line)
{
    prof_call_tree_t* result = ALLOC(prof_call_tree_t);
    result->method = method;
    result->parent = parent;
    result->object = Qnil;
    result->visits = 0;
    result->source_line = source_line;
    result->source_file = source_file;
    result->children = rb_st_init_numtable();
    result->measurement = prof_measurement_create();

    return result;
}

prof_call_tree_t* prof_call_tree_copy(prof_call_tree_t* other)
{
    prof_call_tree_t* result = ALLOC(prof_call_tree_t);
    result->children = rb_st_init_numtable();
    result->object = Qnil;
    result->visits = 0;

    result->method = other->method;
    result->parent = other->parent;
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

void prof_call_tree_merge(prof_call_tree_t* result, prof_call_tree_t* other)
{
    result->measurement->called += other->measurement->called;
    result->measurement->total_time += other->measurement->total_time;
    result->measurement->self_time += other->measurement->self_time;
    result->measurement->wait_time += other->measurement->wait_time;
}

static int prof_call_tree_collect_children(st_data_t key, st_data_t value, st_data_t result)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
    VALUE arr = (VALUE)result;
    rb_ary_push(arr, prof_call_tree_wrap(call_tree));
    return ST_CONTINUE;
}

static int prof_call_tree_mark_children(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
    rb_st_foreach(call_tree->children, prof_call_tree_mark_children, data);
    prof_call_tree_mark(call_tree);
    return ST_CONTINUE;
}

void prof_call_tree_mark(void* data)
{
    if (!data)
        return;

    prof_call_tree_t* call_tree = (prof_call_tree_t*)data;

    if (call_tree->object != Qnil)
        rb_gc_mark(call_tree->object);

    if (call_tree->source_file != Qnil)
        rb_gc_mark(call_tree->source_file);

    prof_method_mark(call_tree->method);
    prof_measurement_mark(call_tree->measurement);

    // Recurse down through the whole call tree but only from the top node
    // to avoid calling mark over and over and over.
    if (!call_tree->parent)
        rb_st_foreach(call_tree->children, prof_call_tree_mark_children, 0);
}

static void prof_call_tree_ruby_gc_free(void* data)
{
    if (data)
    {
        prof_call_tree_t* call_tree = (prof_call_tree_t*)data;
        call_tree->object = Qnil;
    }
}

static int prof_call_tree_free_children(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_tree_t* call_tree = (prof_call_tree_t*)value;
    prof_call_tree_free(call_tree);
    return ST_CONTINUE;
}

void prof_call_tree_free(prof_call_tree_t* call_tree_data)
{
    /* Has this call info object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (call_tree_data->object != Qnil)
    {
        RTYPEDDATA(call_tree_data->object)->data = NULL;
        call_tree_data->object = Qnil;
    }

    // Free children
    rb_st_foreach(call_tree_data->children, prof_call_tree_free_children, 0);
    rb_st_free_table(call_tree_data->children);

    // Free measurement
    prof_measurement_free(call_tree_data->measurement);

    // Finally free self
    xfree(call_tree_data);
}

size_t prof_call_tree_size(const void* data)
{
    return sizeof(prof_call_tree_t);
}

static const rb_data_type_t call_tree_type =
{
    .wrap_struct_name = "CallTree",
    .function =
    {
        .dmark = prof_call_tree_mark,
        .dfree = prof_call_tree_ruby_gc_free,
        .dsize = prof_call_tree_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_call_tree_wrap(prof_call_tree_t* call_tree)
{
    if (call_tree->object == Qnil)
    {
        call_tree->object = TypedData_Wrap_Struct(cRpCallTree, &call_tree_type, call_tree);
    }
    return call_tree->object;
}

static VALUE prof_call_tree_allocate(VALUE klass)
{
    prof_call_tree_t* call_tree = prof_call_tree_create(NULL, NULL, Qnil, 0);
    call_tree->object = prof_call_tree_wrap(call_tree);
    return call_tree->object;
}

prof_call_tree_t* prof_get_call_tree(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_call_tree_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::CallTree instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* =======  Call Tree Table   ========*/
static size_t call_tree_table_insert(st_table* table, st_data_t key, prof_call_tree_t* val)
{
    return rb_st_insert(table, (st_data_t)key, (st_data_t)val);
}

prof_call_tree_t* call_tree_table_lookup(st_table* table, st_data_t key)
{
    st_data_t val;
    if (rb_st_lookup(table, (st_data_t)key, &val))
    {
        return (prof_call_tree_t*)val;
    }
    else
    {
        return NULL;
    }
}

uint32_t prof_call_figure_depth(prof_call_tree_t* call_tree_data)
{
    uint32_t result = 0;

    while (call_tree_data->parent)
    {
        result++;
        call_tree_data = call_tree_data->parent;
    }

    return result;
}

void prof_call_tree_add_parent(prof_call_tree_t* self, prof_call_tree_t* parent)
{
    prof_call_tree_add_child(parent, self);
    self->parent = parent;
}

void prof_call_tree_add_child(prof_call_tree_t* self, prof_call_tree_t* child)
{
    call_tree_table_insert(self->children, child->method->key, child);
}

/* =======  RubyProf::CallTree   ========*/

/* call-seq:
   parent -> call_tree

Returns the CallTree parent call_tree object (the method that called this method).*/
static VALUE prof_call_tree_parent(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    if (call_tree->parent)
        return prof_call_tree_wrap(call_tree->parent);
    else
        return Qnil;
}

/* call-seq:
   callees -> array

Returns an array of call info objects that this method called (ie, children).*/
static VALUE prof_call_tree_children(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    VALUE result = rb_ary_new();
    rb_st_foreach(call_tree->children, prof_call_tree_collect_children, result);
    return result;
}

/* call-seq:
   called -> MethodInfo

Returns the target method. */
static VALUE prof_call_tree_target(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    return prof_method_wrap(call_tree->method);
}

/* call-seq:
   called -> Measurement

Returns the measurement associated with this call_tree. */
static VALUE prof_call_tree_measurement(VALUE self)
{
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    return prof_measurement_wrap(call_tree->measurement);
}

/* call-seq:
   depth -> int

   returns the depth of this call info in the call graph */
static VALUE prof_call_tree_depth(VALUE self)
{
    prof_call_tree_t* call_tree_data = prof_get_call_tree(self);
    uint32_t depth = prof_call_figure_depth(call_tree_data);
    return rb_int_new(depth);
}

/* call-seq:
   source_file => string

return the source file of the method
*/
static VALUE prof_call_tree_source_file(VALUE self)
{
    prof_call_tree_t* result = prof_get_call_tree(self);
    return result->source_file;
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE prof_call_tree_line(VALUE self)
{
    prof_call_tree_t* result = prof_get_call_tree(self);
    return INT2FIX(result->source_line);
}

/* :nodoc: */
static VALUE prof_call_tree_dump(VALUE self)
{
    prof_call_tree_t* call_tree_data = prof_get_call_tree(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("measurement")), prof_measurement_wrap(call_tree_data->measurement));

    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), call_tree_data->source_file);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(call_tree_data->source_line));

    rb_hash_aset(result, ID2SYM(rb_intern("parent")), prof_call_tree_parent(self));
    rb_hash_aset(result, ID2SYM(rb_intern("children")), prof_call_tree_children(self));
    rb_hash_aset(result, ID2SYM(rb_intern("target")), prof_call_tree_target(self));

    return result;
}

/* :nodoc: */
static VALUE prof_call_tree_load(VALUE self, VALUE data)
{
    VALUE target = Qnil;
    VALUE parent = Qnil;
    prof_call_tree_t* call_tree = prof_get_call_tree(self);
    call_tree->object = self;

    VALUE measurement = rb_hash_aref(data, ID2SYM(rb_intern("measurement")));
    call_tree->measurement = prof_get_measurement(measurement);

    call_tree->source_file = rb_hash_aref(data, ID2SYM(rb_intern("source_file")));
    call_tree->source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("source_line"))));

    parent = rb_hash_aref(data, ID2SYM(rb_intern("parent")));
    if (parent != Qnil)
        call_tree->parent = prof_get_call_tree(parent);

    VALUE callees = rb_hash_aref(data, ID2SYM(rb_intern("children")));
    for (int i = 0; i < rb_array_len(callees); i++)
    {
        VALUE call_tree_object = rb_ary_entry(callees, i);
        prof_call_tree_t* call_tree_data = prof_get_call_tree(call_tree_object);

        st_data_t key = call_tree_data->method ? call_tree_data->method->key : method_key(Qnil, 0);
        call_tree_table_insert(call_tree->children, key, call_tree_data);
    }

    target = rb_hash_aref(data, ID2SYM(rb_intern("target")));
    call_tree->method = prof_get_method(target);

    return data;
}

void rp_init_call_tree()
{
    /* CallTree */
    cRpCallTree = rb_define_class_under(mProf, "CallTree", rb_cObject);
    rb_undef_method(CLASS_OF(cRpCallTree), "new");
    rb_define_alloc_func(cRpCallTree, prof_call_tree_allocate);

    rb_define_method(cRpCallTree, "parent", prof_call_tree_parent, 0);
    rb_define_method(cRpCallTree, "children", prof_call_tree_children, 0);
    rb_define_method(cRpCallTree, "target", prof_call_tree_target, 0);
    rb_define_method(cRpCallTree, "measurement", prof_call_tree_measurement, 0);

    rb_define_method(cRpCallTree, "depth", prof_call_tree_depth, 0);
    rb_define_method(cRpCallTree, "source_file", prof_call_tree_source_file, 0);
    rb_define_method(cRpCallTree, "line", prof_call_tree_line, 0);

    rb_define_method(cRpCallTree, "_dump_data", prof_call_tree_dump, 0);
    rb_define_method(cRpCallTree, "_load_data", prof_call_tree_load, 1);
}
