/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_infos.h"
#include "rp_measurement.h"

#define INITIAL_CALL_INFOS_SIZE 2

VALUE cRpCallInfos;

/* =======  Call Infos   ========*/
prof_call_infos_t* prof_get_call_infos(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_call_infos_t* result = DATA_PTR(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::CallInfos instance has already been freed, likely because its profile has been freed.");

    return result;
}

prof_call_infos_t* prof_call_infos_create()
{
    prof_call_infos_t* result = ALLOC(prof_call_infos_t);
    result->start = ALLOC_N(prof_call_info_t*, INITIAL_CALL_INFOS_SIZE);
    result->end = result->start + INITIAL_CALL_INFOS_SIZE;
    result->ptr = result->start;
    result->object = Qnil;
    return result;
}

void prof_call_infos_mark(prof_call_infos_t* call_infos)
{
    if (call_infos->object)
        rb_gc_mark(call_infos->object);

    prof_call_info_t** call_info;
    for (call_info = call_infos->start; call_info < call_infos->ptr; call_info++)
    {
        prof_call_info_mark(*call_info);
    }
}

void prof_call_infos_free(prof_call_infos_t* call_infos)
{
    /* Has this method object been accessed by Ruby?  If
       yes clean it up so to avoid a segmentation fault. */
    if (call_infos->object != Qnil)
    {
        RDATA(call_infos->object)->dmark = NULL;
        RDATA(call_infos->object)->dfree = NULL;
        RDATA(call_infos->object)->data = NULL;
        call_infos->object = Qnil;
    }

    // Note we do not free our call_info structures - since they have no parents they will free themselves
    xfree(call_infos);
}

void prof_call_infos_ruby_gc_free(void* data)
{
    // This object gets freed by its owning method
    prof_call_infos_t* call_infos = (prof_call_infos_t*)data;
    call_infos->object = Qnil;
}

static int prof_call_infos_collect_values(st_data_t key, st_data_t value, st_data_t data)
{
    VALUE result = (VALUE)data;
    prof_call_info_t* call_info_data = (prof_call_info_t*)value;
    VALUE call_info = prof_call_info_wrap(call_info_data);
    rb_ary_push(result, call_info);

    return ST_CONTINUE;
}

static int prof_call_infos_collect_children(st_data_t key, st_data_t value, st_data_t hash)
{
    st_table* callers = (st_table*)hash;
    prof_call_info_t* call_info_data = (prof_call_info_t*)value;

    prof_call_info_t* aggregate_call_info_data = NULL;

    if (st_lookup(callers, call_info_data->method->key, &aggregate_call_info_data))
    {
        prof_call_info_merge(aggregate_call_info_data, call_info_data);
    }
    else
    {
        aggregate_call_info_data = prof_call_info_copy(call_info_data);
        st_insert(callers, call_info_data->method->key, aggregate_call_info_data);
    }

    return ST_CONTINUE;
}

VALUE prof_call_infos_wrap(prof_call_infos_t* call_infos)
{
    if (call_infos->object == Qnil)
    {
        call_infos->object = Data_Wrap_Struct(cRpCallInfos, prof_call_infos_mark, prof_call_infos_ruby_gc_free, call_infos);
    }
    return call_infos->object;
}

void prof_add_call_info(prof_call_infos_t* call_infos, prof_call_info_t* call_info)
{
    if (call_infos->ptr == call_infos->end)
    {
        size_t len = call_infos->ptr - call_infos->start;
        size_t new_capacity = (call_infos->end - call_infos->start) * 2;
        REALLOC_N(call_infos->start, prof_call_info_t*, new_capacity);
        call_infos->ptr = call_infos->start + len;
        call_infos->end = call_infos->start + new_capacity;
    }
    *call_infos->ptr = call_info;
    call_infos->ptr++;
}

/* ================  Call Infos   =================*/
/* Document-class: RubyProf::CallInfos
The RubyProf::MethodInfo class stores profiling data for a method.
One instance of the RubyProf::MethodInfo class is created per method
called per thread.  Thus, if a method is called in two different
thread then there will be two RubyProf::MethodInfo objects
created.  RubyProf::MethodInfo objects can be accessed via
the RubyProf::Profile object.
*/

VALUE prof_call_infos_allocate(VALUE klass)
{
    prof_call_infos_t* call_infos_data = prof_call_infos_create();
    call_infos_data->object = prof_call_infos_wrap(call_infos_data);
    return call_infos_data->object;
}

/* call-seq:
   callers -> array

Returns an array of all CallInfo objects that called this method. */
VALUE prof_call_infos_call_infos(VALUE self)
{
    VALUE result = rb_ary_new();

    prof_call_infos_t* call_infos = prof_get_call_infos(self);
    for (prof_call_info_t** p_call_info = call_infos->start; p_call_info < call_infos->ptr; p_call_info++)
    {
        VALUE call_info = prof_call_info_wrap(*p_call_info);
        rb_ary_push(result, call_info);
    }
    return result;
}

/* call-seq:
   callers -> array

Returns an array of aggregated CallInfo objects that called this method (ie, parents).*/
VALUE prof_call_infos_callers(VALUE self)
{
    st_table* callers = st_init_numtable();

    prof_call_infos_t* call_infos = prof_get_call_infos(self);
    for (prof_call_info_t** p_call_info = call_infos->start; p_call_info < call_infos->ptr; p_call_info++)
    {
        prof_call_info_t* parent = (*p_call_info)->parent;
        if (parent == NULL)
            continue;

        prof_call_info_t* aggregate_call_info_data = NULL;

        if (st_lookup(callers, parent->method->key, &aggregate_call_info_data))
        {
            prof_call_info_merge(aggregate_call_info_data, *p_call_info);
        }
        else
        {
            aggregate_call_info_data = prof_call_info_copy(*p_call_info);
            st_insert(callers, parent->method->key, aggregate_call_info_data);
        }
    }

    VALUE result = rb_ary_new_capa(callers->num_entries);
    st_foreach(callers, prof_call_infos_collect_values, result);
    st_free_table(callers);
    return result;
}

/* call-seq:
   callees -> array

Returns an array of aggregated CallInfo objects that this method called (ie, children).*/
VALUE prof_call_infos_callees(VALUE self)
{
    st_table* callees = st_init_numtable();

    prof_call_infos_t* call_infos = prof_get_call_infos(self);
    for (prof_call_info_t** call_info = call_infos->start; call_info < call_infos->ptr; call_info++)
    {
        st_foreach((*call_info)->children, prof_call_infos_collect_children, (st_data_t)callees);
    }

    VALUE result = rb_ary_new_capa(callees->num_entries);
    st_foreach(callees, prof_call_infos_collect_values, result);
    st_free_table(callees);
    return result;
}

/* :nodoc: */
VALUE prof_call_infos_dump(VALUE self)
{
    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("call_infos")), prof_call_infos_call_infos(self));

    return result;
}

/* :nodoc: */
VALUE prof_call_infos_load(VALUE self, VALUE data)
{
    prof_call_infos_t* call_infos_data = DATA_PTR(self);
    call_infos_data->object = self;

    VALUE call_infos = rb_hash_aref(data, ID2SYM(rb_intern("call_infos")));
    for (int i = 0; i < rb_array_len(call_infos); i++)
    {
        VALUE call_info = rb_ary_entry(call_infos, i);
        prof_call_info_t* call_info_data = prof_get_call_info(call_info);
        prof_add_call_info(call_infos_data, call_info_data);
    }

    return data;
}

void rp_init_call_infos()
{
    cRpCallInfos = rb_define_class_under(mProf, "CallInfos", rb_cData);
    rb_undef_method(CLASS_OF(cRpCallInfos), "new");
    rb_define_alloc_func(cRpCallInfos, prof_call_infos_allocate);

    rb_define_method(cRpCallInfos, "call_infos", prof_call_infos_call_infos, 0);
    rb_define_method(cRpCallInfos, "callers", prof_call_infos_callers, 0);
    rb_define_method(cRpCallInfos, "callees", prof_call_infos_callees, 0);

    rb_define_method(cRpCallInfos, "_dump_data", prof_call_infos_dump, 0);
    rb_define_method(cRpCallInfos, "_load_data", prof_call_infos_load, 1);
}
