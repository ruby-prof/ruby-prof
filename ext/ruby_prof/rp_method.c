/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

VALUE cMethodInfo;

#define RP_REL_GET(r, off) ((r) & (1 << (off)))
#define RP_REL_SET(r, off)                                            \
do {                                                                  \
    r |= (1 << (off));                                                \
} while (0)

/* ================  Helper Functions  =================*/
static VALUE
figure_singleton_name(VALUE klass)
{
    volatile VALUE attached, super;
    volatile VALUE attached_str, super_str;
    volatile VALUE result = Qnil;

    /* We have come across a singleton object. First
       figure out what it is attached to.*/
    attached = rb_iv_get(klass, "__attached__");

    /* Is this a singleton class acting as a metaclass? */
    if (BUILTIN_TYPE(attached) == T_CLASS)
    {
        attached_str = rb_class_name(attached);
        result = rb_str_new2("<Class::");
        rb_str_append(result, attached_str);
        rb_str_cat2(result, ">");
    }

    /* Is this for singleton methods on a module? */
    else if (BUILTIN_TYPE(attached) == T_MODULE)
    {
        attached_str = rb_class_name(attached);
        result = rb_str_new2("<Module::");
        rb_str_append(result, attached_str);
        rb_str_cat2(result, ">");
    }

    /* Is this for singleton methods on an object? */
    else if (BUILTIN_TYPE(attached) == T_OBJECT)
    {
        /* Make sure to get the super class so that we don't
           mistakenly grab a T_ICLASS which would lead to
           unknown method errors. */
        super = rb_class_superclass(klass);
        super_str = rb_class_name(super);
        result = rb_str_new2("<Object::");
        rb_str_append(result, super_str);
        rb_str_cat2(result, ">");
    }

    /* Ok, this could be other things like an array made put onto
       a singleton object (yeah, it happens, see the singleton
       objects test case). */
    else
    {
        result = rb_any_to_s(klass);
    }

    return result;
}

static VALUE
resolve_klass_name(VALUE klass)
{
    volatile VALUE result = Qnil;

    if (klass == 0 || klass == Qnil)
    {
        result = rb_str_new2("[global]");
    }
    else if (BUILTIN_TYPE(klass) == T_MODULE)
    {
        result = rb_class_name(klass);
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON))
    {
        result = figure_singleton_name(klass);
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS)
    {
        result = rb_class_name(klass);
    }
    else
    {
        /* Should never happen. */
        result = rb_str_new2("[unknown]");
    }

    return result;
}

static VALUE
resolve_method_name(ID mid)
{
    volatile VALUE name = Qnil;

    if (RTEST(mid))
    {
        name = rb_id2str(mid);
        return rb_str_dup(name);
    }
    else
    {
        return rb_str_new2("[no method]");
    }
}

static VALUE
full_name(prof_method_t *method_data)
{
    VALUE result = rb_str_dup(method_data->klass_name);
    rb_str_cat2(result, "#");
    rb_str_append(result, method_data->method_name);

    return result;
}

static VALUE
resolve_source_klass(VALUE klass)
{
    volatile VALUE attached;
    unsigned int relation;

    /* We want to group methods according to their source-level
       definitions, not their implementation class. Follow module
       inclusions and singleton classes back to a meaningful root
       while keeping track of these relationships. */

    // klass = method->key->klass;
    relation = 0;

    while (1)
    {
        /* This is a global/unknown class */
        if (klass == 0 || klass == Qnil)
            break;

        /* Is this a singleton class? (most common case) */
        if (BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON))
        {
            /* We have come across a singleton object. First
              figure out what it is attached to.*/
            attached = rb_iv_get(klass, "__attached__");

            /* Is this a singleton class acting as a metaclass?
                Or for singleton methods on a module? */
            if (BUILTIN_TYPE(attached) == T_CLASS ||
                BUILTIN_TYPE(attached) == T_MODULE)
            {
                RP_REL_SET(relation, kModuleSingleton);
                klass = attached;
            }
            /* Is this for singleton methods on an object? */
            else if (BUILTIN_TYPE(attached) == T_OBJECT)
            {
                RP_REL_SET(relation, kObjectSingleton);
                klass = rb_class_superclass(klass);
            }
            /* This is a singleton of an instance of a builtin type. */
            else
            {
                RP_REL_SET(relation, kObjectSingleton);
                klass = rb_class_superclass(klass);
            }
        }
        /* Is this an include for a module?  If so get the actual
            module class since we want to combine all profiling
            results for that module. */
        else if (BUILTIN_TYPE(klass) == T_ICLASS)
        {
            RP_REL_SET(relation, kModuleIncludee);
            klass = RBASIC(klass)->klass;
        }
        /* No transformations apply; so bail. */
        else
        {
            break;
        }
    }

    return klass;
}

static VALUE
resolve_source_klass_name(VALUE source_klass)
{
    volatile VALUE klass_str;
    volatile VALUE result = Qnil;

    if (RTEST(source_klass))
    {
      klass_str = rb_class_name(source_klass);
      result = rb_str_dup(klass_str);
    }
    else
    {
      result = rb_str_new2("[global]");
    }

    return result;
}

st_data_t
method_key(VALUE klass, ID mid)
{
    VALUE resolved_klass = klass;

    /* Is this an include for a module?  If so get the actual
        module class since we want to combine all profiling
        results for that module. */
    if (klass == 0 || klass == Qnil)
    {
        resolved_klass = Qnil;
    }
    else if (BUILTIN_TYPE(klass) == T_ICLASS)
    {
        resolved_klass = RBASIC(klass)->klass;
    }
    return (klass << 4) + (mid << 2);
}

/* ================  prof_method_t   =================*/
static prof_method_t*
prof_get_method(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
    prof_method_t* result = DATA_PTR(self);

    if (!result)
        rb_raise(rb_eRuntimeError, "This RubyProf::MethodInfo instance has already been freed, likely because its profile has been freed.");

    return result;
}

static void
prof_method_set_source_info(prof_method_t* method_data, const char* source_file, int source_line)
{
    if (source_file != NULL)
    {
        size_t len = strlen(source_file) + 1;
        char* buffer = ALLOC_N(char, len);

        MEMCPY(buffer, source_file, char, len);
        method_data->source_file = buffer;
        method_data->line = source_line;
    }
    else
    {
        method_data->source_file = NULL;
        method_data->line = 0;
    }
}

prof_method_t*
prof_method_create(rb_event_flag_t event, VALUE klass, ID mid, int line)
{
    prof_method_t *result = ALLOC(prof_method_t);
    const char* source_file = NULL;

    result->key = method_key(klass, mid);
    result->klass_name = resolve_klass_name(klass);
    result->source_klass_name = resolve_source_klass_name(resolve_source_klass(klass));
    result->method_name = resolve_method_name(mid);


    result->root = false;
    result->excluded = 0;
    result->recursive = 0;

    result->parent_call_infos = method_table_create();
    result->child_call_infos = method_table_create();
    
    result->visits = 0;

    result->object = Qnil;

    source_file = (event != RUBY_EVENT_C_CALL ? rb_sourcefile() : NULL);
    prof_method_set_source_info(result, source_file, line);

    return result;
}

prof_method_t*
prof_method_create_excluded(VALUE klass, ID mid)
{
    prof_method_t* result = prof_method_create(RUBY_EVENT_C_CALL, klass, mid, 0);
    result->excluded = 1;
    return result;
}

static int
prof_method_collect_call_infos(st_data_t key, st_data_t value, st_data_t result)
{
    prof_call_info_t* call_info = (prof_call_info_t*)value;
    VALUE arr = (VALUE)result;
    rb_ary_push(arr, prof_call_info_wrap(call_info));
    return ST_CONTINUE;
}

static int
prof_method_mark_call_infos(st_data_t key, st_data_t value, st_data_t data)
{
    prof_call_info_t* call_info = (prof_call_info_t*)value;
    prof_call_info_mark(call_info);
    return ST_CONTINUE;
}

/* The underlying c structures are freed when the parent profile is freed.
   However, on shutdown the Ruby GC frees objects in any will-nilly order.
   That means the ruby thread object wrapping the c thread struct may
   be freed before the parent profile.  Thus we add in a free function
   for the garbage collector so that if it does get called will nil
   out our Ruby object reference.*/
static void
prof_method_ruby_gc_free(prof_method_t* method)
{
	/* Has this thread object been accessed by Ruby?  If
	   yes clean it up so to avoid a segmentation fault. */
	if (method->object != Qnil)
	{
		RDATA(method->object)->data = NULL;
		RDATA(method->object)->dfree = NULL;
		RDATA(method->object)->dmark = NULL;
	}
	method->object = Qnil;
    method->klass_name = Qnil;
    method->source_klass_name = Qnil;
    method->method_name = Qnil;
}

static void
prof_method_free(prof_method_t* method)
{
	prof_method_ruby_gc_free(method);

    st_free_table(method->parent_call_infos);
    st_free_table(method->child_call_infos);

	xfree(method);
}

void
prof_method_mark(prof_method_t *method)
{
    if (method->klass_name)
        rb_gc_mark(method->klass_name);

    if (method->source_klass_name)
        rb_gc_mark(method->source_klass_name);

    if (method->method_name)
        rb_gc_mark(method->method_name);
    
    if (method->object)
		rb_gc_mark(method->object);

    st_foreach(method->parent_call_infos, prof_method_mark_call_infos, 0);
    st_foreach(method->child_call_infos, prof_method_mark_call_infos, 0);
}

static VALUE
prof_method_allocate(VALUE klass)
{
    prof_method_t* method_data = prof_method_create(0, Qnil, 0, 0);
    method_data->object = Data_Wrap_Struct(cMethodInfo, prof_method_mark, prof_method_ruby_gc_free, method_data);
    return method_data->object;
}

VALUE
prof_method_wrap(prof_method_t *result)
{
  if (result->object == Qnil)
  {
    result->object = Data_Wrap_Struct(cMethodInfo, prof_method_mark, prof_method_ruby_gc_free, result);
  }
  return result->object;
}

prof_method_t *
prof_method_get(VALUE self)
{
    /* Can't use Data_Get_Struct because that triggers the event hook
       ending up in endless recursion. */
	prof_method_t* result = DATA_PTR(self);

	if (!result)
    {
	    rb_raise(rb_eRuntimeError, "This RubyProf::MethodInfo instance has already been freed, likely because its profile has been freed.");
	}

   return result;
}

st_table *
method_table_create()
{
    return st_init_numtable();
}

static int
method_table_free_iterator(st_data_t key, st_data_t value, st_data_t dummy)
{
    prof_method_free((prof_method_t *)value);
    return ST_CONTINUE;
}

void
method_table_free(st_table *table)
{
    st_foreach(table, method_table_free_iterator, 0);
    st_free_table(table);
}

size_t
method_table_insert(st_table *table, st_data_t key, prof_method_t *val)
{
    return st_insert(table, (st_data_t) key, (st_data_t) val);
}

prof_method_t *
method_table_lookup(st_table *table, st_data_t key)
{
    st_data_t val;
    if (st_lookup(table, (st_data_t)key, &val))
    {
      return (prof_method_t *) val;
    }
    else
    {
      return NULL;
    }
}

/* ================  Method Info   =================*/
/* Document-class: RubyProf::MethodInfo
The RubyProf::MethodInfo class stores profiling data for a method.
One instance of the RubyProf::MethodInfo class is created per method
called per thread.  Thus, if a method is called in two different
thread then there will be two RubyProf::MethodInfo objects
created.  RubyProf::MethodInfo objects can be accessed via
the RubyProf::Profile object.
*/

/* call-seq:
   callers -> hash

Returns an array of call info objects that called this method  (ie, parents).*/
static VALUE
prof_method_callers(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    VALUE result = rb_ary_new();
    st_foreach(method->parent_call_infos, prof_method_collect_call_infos, result);
    return result;
}

/* call-seq:
   callees -> hash

Returns an array of call info objects that this method called (ie, children).*/
static VALUE
prof_method_callees(VALUE self)
{
    prof_method_t* method = prof_get_method(self);
    VALUE result = rb_ary_new();
    st_foreach(method->child_call_infos, prof_method_collect_call_infos, result);
    return result;
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE
prof_method_line(VALUE self)
{
    int line = prof_method_get(self)->line;
    return rb_int_new(line);
}

/* call-seq:
   source_file => string

return the source file of the method
*/
static VALUE prof_method_source_file(VALUE self)
{
    prof_method_t *method = prof_method_get(self);
    if (method->source_file)
    {
      return rb_str_new2(method->source_file);
    } 
    else 
    {
        return rb_str_new2("ruby_runtime");
    }
}

/* call-seq:
   klass_name -> string

Returns the name of this method's class.  Singleton classes
will have the form <Object::Object>. */

static VALUE
prof_klass_name(VALUE self)
{
    prof_method_t *method = prof_method_get(self);
    return method->klass_name;
}

/* call-seq:
   source_klass_name -> string

Returns the name of this method's source class. */

static VALUE
prof_source_klass_name(VALUE self)
{
    prof_method_t* method = prof_method_get(self);
    return method->source_klass_name;
}

/* call-seq:
   method_name -> string

Returns the name of this method in the format Object#method.  Singletons
methods will be returned in the format <Object::Object>#method.*/

static VALUE
prof_method_name(VALUE self)
{
    prof_method_t *method = prof_method_get(self);
    return method->method_name;
}

/* call-seq:
   full_name -> string

Returns the full name of this method in the format Object#method.*/

static VALUE
prof_full_name(VALUE self)
{
    prof_method_t *method = prof_method_get(self);
    return full_name(method);
}

/* call-seq:
   root? -> boolean

   Returns the true if this method is at the top of the call stack */
static VALUE
prof_method_root(VALUE self)
{
  prof_method_t *method = prof_method_get(self);
  return method->root ? Qtrue : Qfalse;
}

/* call-seq:
   recursive? -> boolean

   Returns the true if this method is recursive */
static VALUE
prof_method_recursive(VALUE self)
{
    prof_method_t* method = prof_method_get(self);
    return method->recursive ? Qtrue : Qfalse;
}

static VALUE
prof_method_dump(VALUE self)
{
    prof_method_t* method_data = DATA_PTR(self);
    VALUE result = rb_hash_new();

    rb_hash_aset(result, ID2SYM(rb_intern("klass_name")), method_data->klass_name);
    rb_hash_aset(result, ID2SYM(rb_intern("source_klass_name")), method_data->source_klass_name);
    rb_hash_aset(result, ID2SYM(rb_intern("method_name")), method_data->method_name);

    rb_hash_aset(result, ID2SYM(rb_intern("key")), INT2FIX(method_data->key));
    rb_hash_aset(result, ID2SYM(rb_intern("root")), prof_method_root(self));
    rb_hash_aset(result, ID2SYM(rb_intern("recursive")), INT2FIX(method_data->recursive));
    rb_hash_aset(result, ID2SYM(rb_intern("source_file")), method_data->source_file ?
                                                              rb_str_new_cstr(method_data->source_file) :
                                                              Qnil);
    rb_hash_aset(result, ID2SYM(rb_intern("line")), INT2FIX(method_data->line));

    rb_hash_aset(result, ID2SYM(rb_intern("callers")), prof_method_callers(self));
    rb_hash_aset(result, ID2SYM(rb_intern("callees")), prof_method_callees(self));

    return result;
}

static VALUE
prof_method_load(VALUE self, VALUE data)
{
    prof_method_t* method_data = RDATA(self)->data;

    method_data->klass_name = rb_hash_aref(data, ID2SYM(rb_intern("klass_name")));
    method_data->source_klass_name = rb_hash_aref(data, ID2SYM(rb_intern("source_klass_name")));
    method_data->method_name = rb_hash_aref(data, ID2SYM(rb_intern("method_name")));
    method_data->key = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("key"))));

    method_data->root = rb_hash_aref(data, ID2SYM(rb_intern("root"))) == Qtrue ? true : false;
    method_data->recursive = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("recursive"))));

    VALUE source_file = rb_hash_aref(data, ID2SYM(rb_intern("source_file")));
    int source_line = FIX2INT(rb_hash_aref(data, ID2SYM(rb_intern("line"))));
    prof_method_set_source_info(method_data, source_file == Qnil ? NULL : StringValueCStr(source_file), source_line);


    VALUE callers = rb_hash_aref(data, ID2SYM(rb_intern("callers")));
    for (int i = 0; i < rb_array_len(callers); i++)
    {
        VALUE call_info = rb_ary_entry(callers, i);
        prof_call_info_t *call_info_data = prof_get_call_info(call_info);
        st_data_t key = call_info_data->parent ? call_info_data->parent->key : method_key(Qnil, 0);
        call_info_table_insert(method_data->parent_call_infos, key, call_info_data);
    }

    VALUE callees = rb_hash_aref(data, ID2SYM(rb_intern("callees")));
    for (int i = 0; i < rb_array_len(callees); i++)
    {
        VALUE call_info = rb_ary_entry(callees, i);
        prof_call_info_t *call_info_data = prof_get_call_info(call_info);
        call_info_table_insert(method_data->child_call_infos, call_info_data->method->key, call_info_data);
    }
    return data;
}

void rp_init_method_info()
{
    /* MethodInfo */
    cMethodInfo = rb_define_class_under(mProf, "MethodInfo", rb_cObject);
    rb_undef_method(CLASS_OF(cMethodInfo), "new");
    rb_define_alloc_func(cMethodInfo, prof_method_allocate);

    rb_define_method(cMethodInfo, "klass_name", prof_klass_name, 0);
    rb_define_method(cMethodInfo, "source_klass_name", prof_klass_name, 0);
    rb_define_method(cMethodInfo, "method_name", prof_method_name, 0);
    rb_define_method(cMethodInfo, "full_name", prof_full_name, 0);

    rb_define_method(cMethodInfo, "callers", prof_method_callers, 0);
    rb_define_method(cMethodInfo, "callees", prof_method_callees, 0);

    rb_define_method(cMethodInfo, "source_file", prof_method_source_file, 0);
    rb_define_method(cMethodInfo, "line", prof_method_line, 0);

    rb_define_method(cMethodInfo, "root?", prof_method_root, 0);
    rb_define_method(cMethodInfo, "recursive?", prof_method_recursive, 0);

    rb_define_method(cMethodInfo, "_dump_data", prof_method_dump, 0);
    rb_define_method(cMethodInfo, "_load_data", prof_method_load, 1);
}
