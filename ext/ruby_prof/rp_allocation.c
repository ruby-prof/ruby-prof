/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

VALUE cRpAllocation;

prof_allocation_t*
allocations_table_lookup(st_table *table, st_data_t key)
{
    prof_allocation_t* result = NULL;
    st_data_t value;
    if (st_lookup(table, key, &value))
    {
        result = (prof_allocation_t*)value;
    }

    return result;
}

void
allocations_table_insert(st_table *table, st_data_t key, prof_allocation_t * allocation)
{
    st_insert(table, (st_data_t)key, (st_data_t)allocation);
}

st_data_t
allocations_key(VALUE klass, int source_line)
{
    return (klass << 4) + source_line;
}

/* ======   prof_allocation_t  ====== */
prof_allocation_t*
prof_allocation_create(void)
{
    prof_allocation_t *result = ALLOC(prof_allocation_t);
    result->count = 0;
    result->klass = Qnil;
    result->object = Qnil;
    result->memory = 0;
    result->source_line = 0;
    result->source_file = Qnil;

    return result;
}

prof_allocation_t*
prof_allocate_increment(prof_method_t* method, rb_trace_arg_t* trace_arg)
{
    VALUE object = rb_tracearg_object(trace_arg);
    VALUE klass = rb_obj_class(object);

    VALUE source_line = rb_tracearg_lineno(trace_arg);
    st_data_t key = allocations_key(klass, source_line);

    prof_allocation_t* allocation = allocations_table_lookup(method->allocations_table, key);
    if (!allocation)
    {
        VALUE class_path = (RTEST(klass) && !OBJ_FROZEN(klass)) ? rb_class_path_cached(klass) : Qnil;
        const char* class_path_cstr = RTEST(class_path) ? RSTRING_PTR(class_path) : 0;

        allocation = prof_allocation_create();
        allocation->source_line = FIX2INT(source_line);
        allocation->source_file = rb_tracearg_path(trace_arg);
        allocation->klass = klass;
        allocations_table_insert(method->allocations_table, key, allocation);
    }

    allocation->count++;
    allocation->memory += rb_obj_memsize_of(object);

    return allocation;
}

static void
prof_allocation_ruby_gc_free(prof_allocation_t* allocation)
{
    /* Has this thread object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (allocation->object != Qnil)
    {
        RDATA(allocation->object)->data = NULL;
        RDATA(allocation->object)->dfree = NULL;
        RDATA(allocation->object)->dmark = NULL;
    }
    allocation->object = Qnil;
}

void
prof_allocation_free(prof_allocation_t* allocation)
{
    prof_allocation_ruby_gc_free(allocation);
    xfree(allocation);
}

size_t
prof_allocation_size(const void* data)
{
    return sizeof(prof_allocation_t);
}

void
prof_allocation_mark(prof_allocation_t* allocation)
{
    if (allocation->klass != Qnil)
    rb_gc_mark(allocation->klass);
    
    if (allocation->source_file != Qnil)
        rb_gc_mark(allocation->source_file);

    if (allocation->object != Qnil)
        rb_gc_mark(allocation->object);
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

VALUE
prof_allocation_wrap(prof_allocation_t *allocation)
{
    if (allocation->object == Qnil)
    {
        allocation->object = TypedData_Wrap_Struct(cRpAllocation, &allocation_type, allocation);
    }
    return allocation->object;
}

static VALUE
prof_allocation_allocate(VALUE klass)
{
    prof_allocation_t* allocation = prof_allocation_create();
    allocation->object = prof_allocation_wrap(allocation);
    return allocation->object;
}

static prof_allocation_t*
prof_allocation_get(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_allocation_t* result = DATA_PTR(self);
    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::Allocation instance has already been freed, likely because its profile has been freed.");

    return result;
}

/* call-seq:
   klass -> Class

Returns the type of Class being allocated. */
static VALUE
prof_allocation_klass(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return allocation->klass;
}

/* call-seq:
   source_file -> string

Returns the the line number where objects were allocated. */
static VALUE
prof_allocation_source_file(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return allocation->source_file;
}

/* call-seq:
   line -> number

Returns the the line number where objects were allocated. */
static VALUE
prof_allocation_source_line(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return INT2FIX(allocation->source_line);
}

/* call-seq:
   count -> number

Returns the number of times this class has been allocated. */
static VALUE
prof_allocation_count(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return INT2FIX(allocation->count);
}

/* call-seq:
   memory -> number

Returns the amount of memory allocated. */
static VALUE
prof_allocation_memory(VALUE self)
{
    prof_allocation_t* allocation = prof_allocation_get(self);
    return ULL2NUM(allocation->memory);
}

static VALUE
prof_allocation_dump(VALUE self)
{
    prof_allocation_t* allocation = DATA_PTR(self);

    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("klass")), allocation->klass);
    rb_hash_aset(result, ID2SYM(rb_intern("source_line")), INT2FIX(allocation->source_line));
    rb_hash_aset(result, ID2SYM(rb_intern("count")), INT2FIX(allocation->count));
    rb_hash_aset(result, ID2SYM(rb_intern("memory")), LONG2FIX(allocation->memory));

    return result;
}

static VALUE
prof_allocation_load(VALUE self, VALUE data)
{
    prof_allocation_t* allocation = DATA_PTR(self);
    allocation->object = self;

    allocation->klass = rb_hash_aref(data, ID2SYM(rb_intern("klass")));
    allocation->source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("source_line"))));
    allocation->count = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("count"))));
    allocation->memory = FIX2LONG(rb_hash_aref(data, ID2SYM(rb_intern("memory"))));

    return data;
}

void rp_init_allocation(void)
{
    cRpAllocation = rb_define_class_under(mProf, "Allocation", rb_cData);
    rb_undef_method(CLASS_OF(cRpAllocation), "new");
    rb_define_alloc_func(cRpAllocation, prof_allocation_allocate);

    rb_define_method(cRpAllocation, "klass", prof_allocation_klass, 0);
    rb_define_method(cRpAllocation, "source_file", prof_allocation_source_file, 0);
    rb_define_method(cRpAllocation, "line", prof_allocation_source_line, 0);
    rb_define_method(cRpAllocation, "count", prof_allocation_count, 0);
    rb_define_method(cRpAllocation, "memory", prof_allocation_memory, 0);
    rb_define_method(cRpAllocation, "_dump_data", prof_allocation_dump, 0);
    rb_define_method(cRpAllocation, "_load_data", prof_allocation_load, 1);
}
