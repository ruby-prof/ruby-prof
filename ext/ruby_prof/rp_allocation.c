/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_allocation.h"

VALUE cRpAllocation;

prof_allocation_t* allocations_table_lookup(st_table* table, st_data_t key)
{
    prof_allocation_t* result = NULL;
    st_data_t value;
    if (rb_st_lookup(table, key, &value))
    {
        result = (prof_allocation_t*)value;
    }

    return result;
}

void allocations_table_insert(st_table* table, st_data_t key, prof_allocation_t* allocation)
{
    rb_st_insert(table, (st_data_t)key, (st_data_t)allocation);
}

st_data_t allocations_key(VALUE klass, int source_line)
{
    return (klass << 4) + source_line;
}

/* ======   prof_allocation_t  ====== */
prof_allocation_t* prof_allocation_create(void)
{
    prof_allocation_t* result = ALLOC(prof_allocation_t);
    result->count = 0;
    result->klass = Qnil;
    result->klass_name = Qnil;
    result->object = Qnil;
    result->memory = 0;
    result->source_line = 0;
    result->source_file = Qnil;
    result->key = 0;

    return result;
}

prof_allocation_t* prof_get_allocation(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_allocation_t* result = RTYPEDDATA_DATA(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Allocation instance has already been freed, likely because its profile has been freed.");

    return result;
}

prof_allocation_t* prof_allocate_increment(prof_method_t* method, rb_trace_arg_t* trace_arg)
{
    VALUE object = rb_tracearg_object(trace_arg);
    if (BUILTIN_TYPE(object) == T_IMEMO)
        return NULL;

    VALUE klass = rb_obj_class(object);

    int source_line = FIX2INT(rb_tracearg_lineno(trace_arg));
    st_data_t key = allocations_key(klass, source_line);

    prof_allocation_t* allocation = allocations_table_lookup(method->allocations_table, key);
    if (!allocation)
    {
        allocation = prof_allocation_create();
        allocation->source_line = source_line;
        allocation->source_file = rb_tracearg_path(trace_arg);
        allocation->klass_flags = 0;
        allocation->klass = resolve_klass(klass, &allocation->klass_flags);

        allocation->key = key;
        allocations_table_insert(method->allocations_table, key, allocation);
    }

    allocation->count++;
    allocation->memory += rb_obj_memsize_of(object);

    return allocation;
}

static void prof_allocation_ruby_gc_free(void* data)
{
    if (data)
    {
        prof_allocation_t* allocation = (prof_allocation_t*)data;
        allocation->object = Qnil;
    }
}

void prof_allocation_free(prof_allocation_t* allocation)
{
    /* Has this allocation object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (allocation->object != Qnil)
    {
        RTYPEDDATA(allocation->object)->data = NULL;
        allocation->object = Qnil;
    }

    xfree(allocation);
}

size_t prof_allocation_size(const void* data)
{
    return sizeof(prof_allocation_t);
}

void prof_allocation_mark(void* data)
{
    if (!data) return;

    prof_allocation_t* allocation = (prof_allocation_t*)data;
    if (allocation->object != Qnil)
        rb_gc_mark(allocation->object);

    if (allocation->klass != Qnil)
        rb_gc_mark(allocation->klass);

    if (allocation->klass_name != Qnil)
        rb_gc_mark(allocation->klass_name);

    if (allocation->source_file != Qnil)
        rb_gc_mark(allocation->source_file);
}

static const rb_data_type_t allocation_type =
{
    .wrap_struct_name = "Allocation",
    .function =
    {
        .dmark = prof_allocation_mark,
        .dfree = prof_allocation_ruby_gc_free,
        .dsize = prof_allocation_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

VALUE prof_allocation_wrap(prof_allocation_t* allocation)
{
    if (allocation->object == Qnil)
    {
        allocation->object = TypedData_Wrap_Struct(cRpAllocation, &allocation_type, allocation);
    }
    return allocation->object;
}

static VALUE prof_allocation_allocate(VALUE klass)
{
    prof_allocation_t* allocation = prof_allocation_create();
    allocation->object = prof_allocation_wrap(allocation);
    return allocation->object;
}

prof_allocation_t* prof_allocation_get(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_allocation_t* result = RTYPEDDATA_DATA(self);
    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Allocation instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* call-seq:
   klass -> Class

Returns the type of Class being allocated. */
static VALUE prof_allocation_klass_name(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);

    if (allocation->klass_name == Qnil)
        allocation->klass_name = resolve_klass_name(allocation->klass, &allocation->klass_flags);

    return allocation->klass_name;
}

/* call-seq:
   klass_flags -> integer

Returns the klass flags */

static VALUE prof_allocation_klass_flags(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return INT2FIX(allocation->klass_flags);
}

/* call-seq:
   source_file -> string

Returns the the line number where objects were allocated. */
static VALUE prof_allocation_source_file(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return allocation->source_file;
}

/* call-seq:
   line -> number

Returns the the line number where objects were allocated. */
static VALUE prof_allocation_source_line(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return INT2FIX(allocation->source_line);
}

/* call-seq:
   count -> number

Returns the number of times this class has been allocated. */
static VALUE prof_allocation_count(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return INT2FIX(allocation->count);
}

/* call-seq:
   memory -> number

Returns the amount of memory allocated. */
static VALUE prof_allocation_memory(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return ULL2NUM(allocation->memory);
}

/* :nodoc: */
static VALUE prof_allocation_dump(VALUE self)
{
    prof_allocation_t* allocation = prof_get_allocation(self);

    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("key")), INT2FIX(allocation->key));
    rb_hash_aset(result, ID2SYM(rb_intern("klass_name")), prof_allocation_klass_name(self));
    rb_hash_aset(result, ID2SYM(rb_intern("klass_flags")), INT2FIX(allocation->klass_flags));
    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), allocation->source_file);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(allocation->source_line));
    rb_hash_aset(result, ID2SYM(rb_intern("count")), INT2FIX(allocation->count));
    rb_hash_aset(result, ID2SYM(rb_intern("memory")), LONG2FIX(allocation->memory));

    return result;
}

/* :nodoc: */
static VALUE prof_allocation_load(VALUE self, VALUE data)
{
    prof_allocation_t* allocation = prof_get_allocation(self);
    allocation->object = self;

    allocation->key = FIX2LONG(rb_hash_aref(data, ID2SYM(rb_intern("key"))));
    allocation->klass_name = rb_hash_aref(data, ID2SYM(rb_intern("klass_name")));
    allocation->klass_flags = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("klass_flags"))));
    allocation->source_file = rb_hash_aref(data, ID2SYM(rb_intern("source_file")));
    allocation->source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("source_line"))));
    allocation->count = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("count"))));
    allocation->memory = FIX2LONG(rb_hash_aref(data, ID2SYM(rb_intern("memory"))));

    return data;
}

void rp_init_allocation(void)
{
    cRpAllocation = rb_define_class_under(mProf, "Allocation", rb_cObject);
    rb_undef_method(CLASS_OF(cRpAllocation), "new");
    rb_define_alloc_func(cRpAllocation, prof_allocation_allocate);

    rb_define_method(cRpAllocation, "klass_name", prof_allocation_klass_name, 0);
    rb_define_method(cRpAllocation, "klass_flags", prof_allocation_klass_flags, 0);
    rb_define_method(cRpAllocation, "source_file", prof_allocation_source_file, 0);
    rb_define_method(cRpAllocation, "line", prof_allocation_source_line, 0);
    rb_define_method(cRpAllocation, "count", prof_allocation_count, 0);
    rb_define_method(cRpAllocation, "memory", prof_allocation_memory, 0);
    rb_define_method(cRpAllocation, "_dump_data", prof_allocation_dump, 0);
    rb_define_method(cRpAllocation, "_load_data", prof_allocation_load, 1);
}
