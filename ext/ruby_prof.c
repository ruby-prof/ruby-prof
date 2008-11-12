/*
 * Copyright (C) 2008  Shugo Maeda <shugo@ruby-lang.org>
 *                     Charlie Savage <cfis@savagexi.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* ruby-prof tracks the time spent executing every method in ruby programming.
   The main players are:

     prof_result_t     - Its one field, values,  contains the overall results
     thread_data_t     - Stores data about a single thread.  
     prof_stack_t      - The method call stack in a particular thread
     prof_method_t     - Profiling information for each method
     prof_call_info_t  - Keeps track a method's callers and callees. 

  The final resulut is a hash table of thread_data_t, keyed on the thread
  id.  Each thread has an hash a table of prof_method_t, keyed on the
  method id.  A hash table is used for quick look up when doing a profile.
  However, it is exposed to Ruby as an array.
  
  Each prof_method_t has two hash tables, parent and children, of prof_call_info_t.
  These objects keep track of a method's callers (who called the method) and its
  callees (who the method called).  These are keyed the method id, but once again,
  are exposed to Ruby as arrays.  Each prof_call_into_t maintains a pointer to the
  caller or callee method, thereby making it easy to navigate through the call 
  hierarchy in ruby - which is very helpful for creating call graphs.      
*/

#include "ruby_prof.h"


/* ================  Helper Functions  =================*/
static VALUE
figure_singleton_name(VALUE klass)
{
    VALUE result = Qnil;

    /* We have come across a singleton object. First
       figure out what it is attached to.*/
    VALUE attached = rb_iv_get(klass, "__attached__");

    /* Is this a singleton class acting as a metaclass? */
    if (BUILTIN_TYPE(attached) == T_CLASS)
    {
        result = rb_str_new2("<Class::");
        rb_str_append(result, rb_inspect(attached));
        rb_str_cat2(result, ">");
    }

    /* Is this for singleton methods on a module? */
    else if (BUILTIN_TYPE(attached) == T_MODULE)
    {
        result = rb_str_new2("<Module::");
        rb_str_append(result, rb_inspect(attached));
        rb_str_cat2(result, ">");
    }

    /* Is this for singleton methods on an object? */
    else if (BUILTIN_TYPE(attached) == T_OBJECT)
    {
        /* Make sure to get the super class so that we don't
           mistakenly grab a T_ICLASS which would lead to
           unknown method errors. */
#ifdef RCLASS_SUPER
        VALUE super = rb_class_real(RCLASS_SUPER(klass));
#else
        VALUE super = rb_class_real(RCLASS(klass)->super);
#endif
        result = rb_str_new2("<Object::");
        rb_str_append(result, rb_inspect(super));
        rb_str_cat2(result, ">");
    }
    
    /* Ok, this could be other things like an array made put onto
       a singleton object (yeah, it happens, see the singleton
       objects test case). */
    else
    {
        result = rb_inspect(klass);
    }

    return result;
}

static VALUE
klass_name(VALUE klass)
{
    VALUE result = Qnil;
    
    if (klass == 0 || klass == Qnil)
    {
        result = rb_str_new2("Global");
    }
    else if (BUILTIN_TYPE(klass) == T_MODULE)
    {
        result = rb_inspect(klass);
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON))
    {
        result = figure_singleton_name(klass);
    }
    else if (BUILTIN_TYPE(klass) == T_CLASS)
    {
        result = rb_inspect(klass);
    }
    else
    {
        /* Should never happen. */
        result = rb_str_new2("Unknown");
    }

    return result;
}

static VALUE
method_name(ID mid, int depth)
{
    VALUE result;

    if (mid == ID_ALLOCATOR) 
        result = rb_str_new2("allocate");
    else if (mid == 0)
        result = rb_str_new2("[No method]");
    else
        result = rb_String(ID2SYM(mid));
    
    if (depth > 0)
    {
      char buffer[65];
      sprintf(buffer, "%i", depth);
      rb_str_cat2(result, "-");
      rb_str_cat2(result, buffer);
    }

    return result;
}

static VALUE
full_name(VALUE klass, ID mid, int depth)
{
  VALUE result = klass_name(klass);
  rb_str_cat2(result, "#");
  rb_str_append(result, method_name(mid, depth));
  
  return result;
}

/* ================  Stack Handling   =================*/
/* Creates a stack of prof_frame_t to keep track
   of timings for active methods. */
static prof_stack_t *
stack_create()
{
    prof_stack_t *stack = ALLOC(prof_stack_t);
    stack->start = ALLOC_N(prof_frame_t, INITIAL_STACK_SIZE);
    stack->ptr = stack->start;
    stack->end = stack->start + INITIAL_STACK_SIZE;
    return stack;
}

static void
stack_free(prof_stack_t *stack)
{
    xfree(stack->start);
    xfree(stack);
}

static prof_frame_t *
stack_push(prof_stack_t *stack)
{
  /* Is there space on the stack?  If not, double
     its size. */
  if (stack->ptr == stack->end)
  {
    size_t len = stack->ptr - stack->start;
    size_t new_capacity = (stack->end - stack->start) * 2;
    REALLOC_N(stack->start, prof_frame_t, new_capacity);
    stack->ptr = stack->start + len;
    stack->end = stack->start + new_capacity;
  }
  return stack->ptr++;
}

static prof_frame_t *
stack_pop(prof_stack_t *stack)
{
    if (stack->ptr == stack->start)
      return NULL;
    else
      return --stack->ptr;
}

static prof_frame_t *
stack_peek(prof_stack_t *stack)
{
    if (stack->ptr == stack->start)
      return NULL;
    else
      return stack->ptr - 1;
}

/* ================  Method Key   =================*/
static int 
method_table_cmp(prof_method_key_t *key1, prof_method_key_t *key2) 
{
    return (key1->klass != key2->klass) || 
           (key1->mid != key2->mid) || 
           (key1->depth != key2->depth);
}

static int 
method_table_hash(prof_method_key_t *key) 
{
   return key->key;
}

static struct st_hash_type type_method_hash = {
    method_table_cmp,
    method_table_hash
};

static void
method_key(prof_method_key_t* key, VALUE klass, ID mid, int depth)
{
    key->klass = klass;
    key->mid = mid;
    key->depth = depth;
    key->key = (klass << 4) + (mid << 2) + depth;
}


/* ================  Call Info   =================*/
static st_table *
call_info_table_create()
{
  return st_init_table(&type_method_hash);
}

static size_t
call_info_table_insert(st_table *table, const prof_method_key_t *key, prof_call_info_t *val)
{
  return st_insert(table, (st_data_t) key, (st_data_t) val);
}

static prof_call_info_t *
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

static void
call_info_table_free(st_table *table)
{
    st_free_table(table);
}

/* Document-class: RubyProf::CallInfo
RubyProf::CallInfo is a helper class used by RubyProf::MethodInfo
to keep track of which child methods were called and how long
they took to execute. */

/* :nodoc: */
static prof_call_info_t *
prof_call_info_create(prof_method_t* method, prof_call_info_t* parent)
{
    prof_call_info_t *result = ALLOC(prof_call_info_t);
    result->object = Qnil;
    result->target = method;
    result->parent = parent;
    result->call_infos = call_info_table_create();
    result->children = Qnil;

    result->called = 0;
    result->total_time = 0;
    result->self_time = 0;
    result->wait_time = 0;
    result->line = 0;
    return result;
}

static void
prof_call_info_mark(prof_call_info_t *call_info)
{
  rb_gc_mark(prof_method_wrap(call_info->target));
  rb_gc_mark(call_info->children);
  if (call_info->parent)
    rb_gc_mark(prof_call_info_wrap(call_info->parent));
}

static void
prof_call_info_free(prof_call_info_t *call_info)
{
  call_info_table_free(call_info->call_infos); 
  xfree(call_info);
}

static VALUE
prof_call_info_wrap(prof_call_info_t *call_info)
{
  if (call_info->object == Qnil)
  {
    call_info->object = Data_Wrap_Struct(cCallInfo, prof_call_info_mark, prof_call_info_free, call_info);
  }
  return call_info->object;
}

static prof_call_info_t *
prof_get_call_info_result(VALUE obj)
{
    if (BUILTIN_TYPE(obj) != T_DATA)
    {
        /* Should never happen */
      rb_raise(rb_eTypeError, "Not a call info object");
    }
    return (prof_call_info_t *) DATA_PTR(obj);
}


/* call-seq:
   called -> MethodInfo

Returns the target method. */
static VALUE
prof_call_info_target(VALUE self)
{
    /* Target is a pointer to a method_info - so we have to be careful
       about the GC.  We will wrap the method_info but provide no
       free method so the underlying object is not freed twice! */
    
    prof_call_info_t *result = prof_get_call_info_result(self);
    return prof_method_wrap(result->target);
}

/* call-seq:
   called -> int

Returns the total amount of time this method was called. */
static VALUE
prof_call_info_called(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info_result(self);
    return INT2NUM(result->called);
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE
prof_call_info_line(VALUE self)
{
  prof_call_info_t *result = prof_get_call_info_result(self);
  return rb_int_new(result->line);
}

/* call-seq:
   total_time -> float

Returns the total amount of time spent in this method and its children. */
static VALUE
prof_call_info_total_time(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info_result(self);
    return rb_float_new(convert_measurement(result->total_time));
}

/* call-seq:
   self_time -> float

Returns the total amount of time spent in this method. */
static VALUE
prof_call_info_self_time(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info_result(self);

    return rb_float_new(convert_measurement(result->self_time));
}

/* call-seq:
   wait_time -> float

Returns the total amount of time this method waited for other threads. */
static VALUE
prof_call_info_wait_time(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info_result(self);

    return rb_float_new(convert_measurement(result->wait_time));
}

/* call-seq:
   parent -> call_info

Returns the call_infos parent call_info object (the method that called this method).*/
static VALUE
prof_call_info_parent(VALUE self)
{
    prof_call_info_t *result = prof_get_call_info_result(self);
    if (result->parent)
      return prof_call_info_wrap(result->parent);
    else
      return Qnil;
}

static int
prof_call_info_collect_children(st_data_t key, st_data_t value, st_data_t result)
{
    prof_call_info_t *call_info = (prof_call_info_t *) value;
    VALUE arr = (VALUE) result;
    rb_ary_push(arr, prof_call_info_wrap(call_info));
    return ST_CONTINUE;
}

/* call-seq:
   children -> hash

Returns an array of call info objects of methods that this method 
called (ie, children).*/
static VALUE
prof_call_info_children(VALUE self)
{
    prof_call_info_t *call_info = prof_get_call_info_result(self);
    if (call_info->children == Qnil)
    {
      call_info->children = rb_ary_new();
      st_foreach(call_info->call_infos, prof_call_info_collect_children, call_info->children);
    }
    return call_info->children;
}

/* ================  Call Infos   =================*/
static prof_call_infos_t*
prof_call_infos_create()
{
   prof_call_infos_t *result = ALLOC(prof_call_infos_t);
   result->start = ALLOC_N(prof_call_info_t*, INITIAL_CALL_INFOS_SIZE);
   result->end = result->start + INITIAL_CALL_INFOS_SIZE;
   result->ptr = result->start;
   result->object = Qnil;
   return result;
}

static void
prof_call_infos_free(prof_call_infos_t *call_infos)
{
  xfree(call_infos->start);
  xfree(call_infos);
}

static void
prof_add_call_info(prof_call_infos_t *call_infos, prof_call_info_t *call_info)
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

static VALUE
prof_call_infos_wrap(prof_call_infos_t *call_infos)
{
  if (call_infos->object == Qnil)
  {
    prof_call_info_t **i;
    call_infos->object = rb_ary_new();
    for(i=call_infos->start; i<call_infos->ptr; i++)
    {
      VALUE call_info = prof_call_info_wrap(*i);
      rb_ary_push(call_infos->object, call_info);
    }
  }
  return call_infos->object;
}


/* ================  Method Info   =================*/
/* Document-class: RubyProf::MethodInfo
The RubyProf::MethodInfo class stores profiling data for a method.
One instance of the RubyProf::MethodInfo class is created per method
called per thread.  Thus, if a method is called in two different
thread then there will be two RubyProf::MethodInfo objects
created.  RubyProf::MethodInfo objects can be accessed via
the RubyProf::Result object.
*/

static prof_method_t*
prof_method_create(prof_method_key_t *key, const char* source_file, int line)
{
    prof_method_t *result = ALLOC(prof_method_t);
    result->object = Qnil;
    result->key = ALLOC(prof_method_key_t);
    method_key(result->key, key->klass, key->mid, key->depth);   

    result->call_infos = prof_call_infos_create();

    result->active = 0;

    if (source_file != NULL) 
    {
      int len = strlen(source_file) + 1;    
      char *buffer = ALLOC_N(char, len);

      MEMCPY(buffer, source_file, char, len);
      result->source_file = buffer;
    }
    else 
    {    
      result->source_file = source_file;
    }      
    result->line = line;

    return result;
}

static void
prof_method_mark(prof_method_t *method)
{
  rb_gc_mark(method->call_infos->object);
  rb_gc_mark(method->key->klass);
}

static void
prof_method_free(prof_method_t *method)
{
  if (method->source_file)
  {
    xfree((char*)method->source_file);    
  }

  prof_call_infos_free(method->call_infos);
  xfree(method->key);
  xfree(method);
}

static VALUE
prof_method_wrap(prof_method_t *result)
{
  if (result->object == Qnil)
  {
    result->object = Data_Wrap_Struct(cMethodInfo, prof_method_mark, prof_method_free, result);
  }
  return result->object;
}

static prof_method_t *
get_prof_method(VALUE obj)
{
    return (prof_method_t *) DATA_PTR(obj);
}

/* call-seq:
   line_no -> int

   returns the line number of the method */
static VALUE
prof_method_line(VALUE self)
{
    return rb_int_new(get_prof_method(self)->line);
}

/* call-seq:
   source_file => string

return the source file of the method 
*/
static VALUE prof_method_source_file(VALUE self)
{
    const char* sf = get_prof_method(self)->source_file;
    if(!sf)
    {
      return rb_str_new2("ruby_runtime");
    }
    else
    {
      return rb_str_new2(sf);
    }
}


/* call-seq:
   method_class -> klass

Returns the Ruby klass that owns this method. */
static VALUE
prof_method_klass(VALUE self)
{
    prof_method_t *result = get_prof_method(self);
    return result->key->klass;
}

/* call-seq:
   method_id -> ID

Returns the id of this method. */
static VALUE
prof_method_id(VALUE self)
{
    prof_method_t *result = get_prof_method(self);
    return ID2SYM(result->key->mid);
}

/* call-seq:
   klass_name -> string

Returns the name of this method's class.  Singleton classes
will have the form <Object::Object>. */

static VALUE
prof_klass_name(VALUE self)
{
    prof_method_t *method = get_prof_method(self);
    return klass_name(method->key->klass);
}

/* call-seq:
   method_name -> string

Returns the name of this method in the format Object#method.  Singletons
methods will be returned in the format <Object::Object>#method.*/

static VALUE
prof_method_name(VALUE self, int depth)
{
    prof_method_t *method = get_prof_method(self);
    return method_name(method->key->mid, depth);
}

/* call-seq:
   full_name -> string

Returns the full name of this method in the format Object#method.*/

static VALUE
prof_full_name(VALUE self)
{
    prof_method_t *method = get_prof_method(self);
    return full_name(method->key->klass, method->key->mid, method->key->depth);
}

/* call-seq:
   call_infos -> Array of call_info

Returns an array of call info objects that contain profiling information 
about the current method.*/
static VALUE
prof_method_call_infos(VALUE self)
{
    prof_method_t *method = get_prof_method(self);
    return prof_call_infos_wrap(method->call_infos);
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

/* ================  Method Table   =================*/
static st_table *
method_table_create()
{
  return st_init_table(&type_method_hash);
}

static size_t
method_table_insert(st_table *table, const prof_method_key_t *key, prof_method_t *val)
{
  return st_insert(table, (st_data_t) key, (st_data_t) val);
}

static prof_method_t *
method_table_lookup(st_table *table, const prof_method_key_t* key)
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


static void
method_table_free(st_table *table)
{
    /* Don't free the contents since they are wrapped by
       Ruby objects! */
    st_free_table(table);
}


/* ================  Thread Handling   =================*/

/* ---- Keeps track of thread's stack and methods ---- */
static thread_data_t*
thread_data_create()
{
    thread_data_t* result = ALLOC(thread_data_t);
    result->stack = stack_create();
    result->method_table = method_table_create();
    result->last_switch = get_measurement();
    return result;
}

static void
thread_data_free(thread_data_t* thread_data)
{
    method_table_free(thread_data->method_table);
    stack_free(thread_data->stack);
    xfree(thread_data);
}

/* ---- Hash, keyed on thread, that stores thread's stack
        and methods---- */

static st_table *
threads_table_create()
{
    return st_init_numtable();
}

static size_t
threads_table_insert(st_table *table, VALUE thread, thread_data_t *thread_data)
{
    /* Its too slow to key on the real thread id so just typecast thread instead. */
    return st_insert(table, (st_data_t) thread, (st_data_t) thread_data);
}

static thread_data_t *
threads_table_lookup(st_table *table, VALUE thread_id)
{
    thread_data_t* result;
    st_data_t val;

    /* Its too slow to key on the real thread id so just typecast thread instead. */
    if (st_lookup(table, (st_data_t) thread_id, &val))
    {
      result = (thread_data_t *) val;
    }
    else
    {
        result = thread_data_create();
        result->thread_id = thread_id;

        /* Insert the table */
        threads_table_insert(threads_tbl, thread_id, result);
    }
    return result;
}

static int
free_thread_data(st_data_t key, st_data_t value, st_data_t dummy)
{
    thread_data_free((thread_data_t*)value);
    return ST_CONTINUE;
}


static void
threads_table_free(st_table *table)
{
    st_foreach(table, free_thread_data, 0);
    st_free_table(table);
}


static int
collect_threads(st_data_t key, st_data_t value, st_data_t result)
{
    /* Although threads are keyed on an id, that is actually a 
       pointer to the VALUE object of the thread.  So its bogus.
       However, in thread_data is the real thread id stored
       as an int. */
    thread_data_t* thread_data = (thread_data_t*) value;
    VALUE threads_hash = (VALUE) result;

    VALUE methods = rb_ary_new();

    /* Now collect an array of all the called methods */
    st_table* method_table = thread_data->method_table;
    st_foreach(method_table, collect_methods, methods);
 
    /* Store the results in the threads hash keyed on the thread id. */
    rb_hash_aset(threads_hash, thread_data->thread_id, methods);

    return ST_CONTINUE;
}


/* ================  Profiling    =================*/
/* Copied from eval.c */
#ifdef DEBUG
static char *
get_event_name(rb_event_flag_t event)
{
  switch (event) {
    case RUBY_EVENT_LINE:
  return "line";
    case RUBY_EVENT_CLASS:
  return "class";
    case RUBY_EVENT_END:
  return "end";
    case RUBY_EVENT_CALL:
  return "call";
    case RUBY_EVENT_RETURN:
  return "return";
    case RUBY_EVENT_C_CALL:
  return "c-call";
    case RUBY_EVENT_C_RETURN:
  return "c-return";
    case RUBY_EVENT_RAISE:
  return "raise";
    default:
  return "unknown";
  }
}
#endif

static prof_method_t* 
get_method(rb_event_flag_t event, NODE *node, VALUE klass, ID mid, int depth, st_table* method_table)
{
    prof_method_key_t key;
    prof_method_t *method = NULL;
    
    method_key(&key, klass, mid, depth);
    method = method_table_lookup(method_table, &key);

    if (!method)
    {
      const char* source_file = rb_sourcefile();
      int line = rb_sourceline();
      
      /* Line numbers are not accurate for c method calls */
      if (event == RUBY_EVENT_C_CALL)
      {
        line = 0;
        source_file = NULL;
      }
        
      method = prof_method_create(&key, source_file, line);
      method_table_insert(method_table, method->key, method);
    }
    return method;
}

static void
update_result(prof_measure_t total_time,
              prof_frame_t *parent_frame, 
              prof_frame_t *frame)
{
    prof_measure_t self_time = total_time - frame->child_time - frame->wait_time;

    prof_call_info_t *call_info = frame->call_info;
    
    /* Update information about the current method */
    call_info->called++;
    call_info->total_time += total_time;
    call_info->self_time += self_time;
    call_info->wait_time += frame->wait_time;

    /* Note where the current method was called from */
    if (parent_frame)
      call_info->line = parent_frame->line;
}

static thread_data_t *
switch_thread(VALUE thread_id, prof_measure_t now)
{
    prof_frame_t *frame = NULL;
    prof_measure_t wait_time = 0;
    
    /* Get new thread information. */
    thread_data_t *thread_data = threads_table_lookup(threads_tbl, thread_id);

    /* How long has this thread been waiting? */
    wait_time = now - thread_data->last_switch;
    thread_data->last_switch = 0;

    /* Get the frame at the top of the stack.  This may represent
       the current method (EVENT_LINE, EVENT_RETURN)  or the
       previous method (EVENT_CALL).*/
    frame = stack_peek(thread_data->stack);
  
    if (frame)
      frame->wait_time += wait_time;
      
    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (last_thread_data)
      last_thread_data->last_switch = now;
      
    last_thread_data = thread_data;
    return thread_data;
}

static prof_frame_t*
pop_frame(thread_data_t *thread_data, prof_measure_t now)
{
  prof_frame_t *frame = NULL;
  prof_frame_t* parent_frame = NULL;
  prof_measure_t total_time;

  frame = stack_pop(thread_data->stack);
    
  /* Frame can be null.  This can happen if RubProf.start is called from
     a method that exits.  And it can happen if an exception is raised
     in code that is being profiled and the stack unwinds (RubProf is
     not notified of that by the ruby runtime. */
  if (frame == NULL) return NULL;

  /* Calculate the total time this method took */
  total_time = now - frame->start_time;

  /* Now deactivate the method */
  frame->call_info->target->active = 0;

  parent_frame = stack_peek(thread_data->stack);
  if (parent_frame)
  {
    parent_frame->child_time += total_time;
  }
    
  update_result(total_time, parent_frame, frame);
  return frame;
}

static int 
pop_frames(st_data_t key, st_data_t value, st_data_t now_arg)
{
    VALUE thread_id = (VALUE)key;
    thread_data_t* thread_data = (thread_data_t *) value;
    prof_measure_t now = *(prof_measure_t *) now_arg;

    if (!last_thread_data || last_thread_data->thread_id != thread_id)
      thread_data = switch_thread(thread_id, now);
    else
      thread_data = last_thread_data;

    while (pop_frame(thread_data, now))
    {
    }
    
    return ST_CONTINUE;
}

static void 
prof_pop_threads()
{
    /* Get current measurement*/
    prof_measure_t now = get_measurement();
    st_foreach(threads_tbl, pop_frames, (st_data_t) &now);
}


#ifdef RUBY_VM
static void
prof_event_hook(rb_event_flag_t event, VALUE data, VALUE self, ID mid, VALUE klass)
#else
static void
prof_event_hook(rb_event_flag_t event, NODE *node, VALUE self, ID mid, VALUE klass)
#endif
{
    
    VALUE thread = Qnil;
    VALUE thread_id = Qnil;
    prof_measure_t now = 0;
    thread_data_t* thread_data = NULL;
    prof_frame_t *frame = NULL;


#ifdef RUBY_VM

    if (event != RUBY_EVENT_C_CALL && event != RUBY_EVENT_C_RETURN) {
        rb_frame_method_id_and_class(&mid, &klass);
    }
#endif

#ifdef DEBUG
    /*  This code is here for debug purposes - uncomment it out
        when debugging to see a print out of exactly what the
        profiler is tracing. */
    {
        char* key = 0;
        static VALUE last_thread_id = Qnil;

        VALUE thread = rb_thread_current();
        VALUE thread_id = rb_obj_id(thread);
        char* class_name = NULL;
        char* method_name = rb_id2name(mid);
        char* source_file = rb_sourcefile();
        unsigned int source_line = rb_sourceline();

        char* event_name = get_event_name(event);

        if (klass != 0)
          klass = (BUILTIN_TYPE(klass) == T_ICLASS ? RBASIC(klass)->klass : klass);

        class_name = rb_class2name(klass);

        if (last_thread_id != thread_id)
          printf("\n");

        printf("%2u: %-8s :%2d  %s#%s\n",
               thread_id, event_name, source_line, class_name, method_name);
        fflush(stdout);
        last_thread_id = thread_id;               
    }
#endif
    
    /* Special case - skip any methods from the mProf 
       module, such as Prof.stop, since they clutter
       the results but aren't important to them results. */
    if (self == mProf) return;

    /* Get current measurement*/
    now = get_measurement();
    
    /* Get the current thread information. */
    thread = rb_thread_current();
    thread_id = rb_obj_id(thread);

    if (exclude_threads_tbl &&
        st_lookup(exclude_threads_tbl, (st_data_t) thread_id, 0)) 
    {
      return;
    }    
    
    /* Was there a context switch? */
    if (!last_thread_data || last_thread_data->thread_id != thread_id)
      thread_data = switch_thread(thread_id, now);
    else
      thread_data = last_thread_data;
    
    /* Get the current frame for the current thread. */
    frame = stack_peek(thread_data->stack);

    switch (event) {
    case RUBY_EVENT_LINE:
    {
      /* Keep track of the current line number in this method.  When
         a new method is called, we know what line number it was 
         called from. */
      if (frame)
      {
        frame->line = rb_sourceline();
        break;
      }

      /* If we get here there was no frame, which means this is 
         the first method seen for this thread, so fall through
         to below to create it. */
    }
    case RUBY_EVENT_CALL:
    case RUBY_EVENT_C_CALL:
    {
        prof_call_info_t *call_info = NULL;
        prof_method_t *method = NULL;

        /* Is this an include for a module?  If so get the actual
           module class since we want to combine all profiling
           results for that module. */
        
        if (klass != 0)
          klass = (BUILTIN_TYPE(klass) == T_ICLASS ? RBASIC(klass)->klass : klass);
          
        /* Assume this is the first time we have called this method. */
        method = get_method(event, node, klass, mid, 0, thread_data->method_table);

        /* Check for a recursive call */
        if (method->active)
        {
          /* Yes, this method is already active */
          method = get_method(event, node, klass, mid, method->key->depth + 1, thread_data->method_table);
        }
        else
        {
          /* No, so make it active */
          method->active = 1;
        }

        if (!frame)
        {
          call_info = prof_call_info_create(method, NULL);
          prof_add_call_info(method->call_infos, call_info);
        }
        else
        {
          call_info = call_info_table_lookup(frame->call_info->call_infos, method->key);

          if (!call_info)
          {
            call_info = prof_call_info_create(method, frame->call_info);
            call_info_table_insert(frame->call_info->call_infos, method->key, call_info);
            prof_add_call_info(method->call_infos, call_info);
          }
        }

        /* Push a new frame onto the stack */
        frame = stack_push(thread_data->stack);
        frame->call_info = call_info;
        frame->start_time = now;
        frame->wait_time = 0;
        frame->child_time = 0;
        frame->line = rb_sourceline();

        break;
    }
    case RUBY_EVENT_RETURN:
    case RUBY_EVENT_C_RETURN:
    {
        pop_frame(thread_data, now);
        break;
      }
    }
}


/* ========  ProfResult ============== */

/* Document-class: RubyProf::Result
The RubyProf::Result class is used to store the results of a 
profiling run.  And instace of the class is returned from
the methods RubyProf#stop and RubyProf#profile.

RubyProf::Result has one field, called threads, which is a hash
table keyed on thread ID.  For each thread id, the hash table
stores another hash table that contains profiling information
for each method called during the threads execution.  That
hash table is keyed on method name and contains
RubyProf::MethodInfo objects. */


static void
prof_result_mark(prof_result_t *prof_result)
{
    VALUE threads = prof_result->threads;
    rb_gc_mark(threads);
}

static void
prof_result_free(prof_result_t *prof_result)
{
    prof_result->threads = Qnil;
    xfree(prof_result);
}

static VALUE
prof_result_new()
{
    prof_result_t *prof_result = ALLOC(prof_result_t);

    /* Wrap threads in Ruby regular Ruby hash table. */
    prof_result->threads = rb_hash_new();
    st_foreach(threads_tbl, collect_threads, prof_result->threads);

    return Data_Wrap_Struct(cResult, prof_result_mark, prof_result_free, prof_result);
}


static prof_result_t *
get_prof_result(VALUE obj)
{
    if (BUILTIN_TYPE(obj) != T_DATA ||
      RDATA(obj)->dfree != (RUBY_DATA_FUNC) prof_result_free)
    {
        /* Should never happen */
      rb_raise(rb_eTypeError, "wrong result object");
    }
    return (prof_result_t *) DATA_PTR(obj);
}

/* call-seq:
   threads -> Hash

Returns a hash table keyed on thread ID.  For each thread id,
the hash table stores another hash table that contains profiling
information for each method called during the threads execution.
That hash table is keyed on method name and contains 
RubyProf::MethodInfo objects. */
static VALUE
prof_result_threads(VALUE self)
{
    prof_result_t *prof_result = get_prof_result(self);
    return prof_result->threads;
}



/* call-seq:
   measure_mode -> measure_mode
   
   Returns what ruby-prof is measuring.  Valid values include:
   
   *RubyProf::PROCESS_TIME - Measure process time.  This is default.  It is implemented using the clock functions in the C Runtime library.
   *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows
   *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms. 
   *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
   *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
   *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
   *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/
static VALUE
prof_get_measure_mode(VALUE self)
{
    return INT2NUM(measure_mode);
}

/* call-seq:
   measure_mode=value -> void
   
   Specifies what ruby-prof should measure.  Valid values include:
   
   *RubyProf::PROCESS_TIME - Measure process time.  This is default.  It is implemented using the clock functions in the C Runtime library.
   *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows
   *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms. 
   *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
   *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
   *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
   *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/
static VALUE
prof_set_measure_mode(VALUE self, VALUE val)
{
    long mode = NUM2LONG(val);

    if (threads_tbl)
    {
      rb_raise(rb_eRuntimeError, "can't set measure_mode while profiling");
    }

    switch (mode) {
      case MEASURE_PROCESS_TIME:
        get_measurement = measure_process_time;
        convert_measurement = convert_process_time;
        break;
        
      case MEASURE_WALL_TIME:
        get_measurement = measure_wall_time;
        convert_measurement = convert_wall_time;
        break;
        
      #if defined(MEASURE_CPU_TIME)
      case MEASURE_CPU_TIME:
        if (cpu_frequency == 0)
            cpu_frequency = get_cpu_frequency();
        get_measurement = measure_cpu_time;
        convert_measurement = convert_cpu_time;
        break;
      #endif
              
      #if defined(MEASURE_ALLOCATIONS)
      case MEASURE_ALLOCATIONS:
        get_measurement = measure_allocations;
        convert_measurement = convert_allocations;
        break;
      #endif
        
      #if defined(MEASURE_MEMORY)
      case MEASURE_MEMORY:
        get_measurement = measure_memory;
        convert_measurement = convert_memory;
        break;
      #endif

      #if defined(MEASURE_GC_RUNS)
      case MEASURE_GC_RUNS:
        get_measurement = measure_gc_runs;
        convert_measurement = convert_gc_runs;
        break;
      #endif

      #if defined(MEASURE_GC_TIME)
      case MEASURE_GC_TIME:
        get_measurement = measure_gc_time;
        convert_measurement = convert_gc_time;
        break;
      #endif

      default:
        rb_raise(rb_eArgError, "invalid mode: %ld", mode);
        break;
    }
    
    measure_mode = mode;
    return val;
}

/* call-seq:
   exclude_threads= -> void

   Specifies what threads ruby-prof should exclude from profiling */
static VALUE
prof_set_exclude_threads(VALUE self, VALUE threads)
{
    int i;

    if (threads_tbl != NULL)
    {
      rb_raise(rb_eRuntimeError, "can't set exclude_threads while profiling");
    }

    /* Stay simple, first free the old hash table */
    if (exclude_threads_tbl)
    {
      st_free_table(exclude_threads_tbl);
      exclude_threads_tbl = NULL;
    }

    /* Now create a new one if the user passed in any threads */
    if (threads != Qnil)
    {
      Check_Type(threads, T_ARRAY);
      exclude_threads_tbl = st_init_numtable();

      for (i=0; i < RARRAY_LEN(threads); ++i) 
      {
        VALUE thread = rb_ary_entry(threads, i);
        st_insert(exclude_threads_tbl, (st_data_t) rb_obj_id(thread), 0);
      }
    }    
    return threads;
}


/* =========  Profiling ============= */
void
prof_install_hook()
{
#ifdef RUBY_VM
    rb_add_event_hook(prof_event_hook,
          RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
          RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN 
          | RUBY_EVENT_LINE, Qnil);
#else
    rb_add_event_hook(prof_event_hook,
          RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
          RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN 
          | RUBY_EVENT_LINE);
#endif

#if defined(TOGGLE_GC_STATS)
    rb_gc_enable_stats();
#endif
}

void
prof_remove_hook()
{
#if defined(TOGGLE_GC_STATS)
    rb_gc_disable_stats();
#endif

    /* Now unregister from event   */
    rb_remove_event_hook(prof_event_hook);
}



/* call-seq:
   running? -> boolean
   
   Returns whether a profile is currently running.*/
static VALUE
prof_running(VALUE self)
{
    if (threads_tbl != NULL)
        return Qtrue;
    else
        return Qfalse;
}

/* call-seq:
   start -> RubyProf
   
   Starts recording profile data.*/
static VALUE
prof_start(VALUE self)
{
    if (threads_tbl != NULL)
    {
        rb_raise(rb_eRuntimeError, "RubyProf.start was already called");
    }

    /* Setup globals */
    last_thread_data = NULL;
    threads_tbl = threads_table_create();

    prof_install_hook();              
    return self;
}    

/* call-seq:
   pause -> RubyProf

   Pauses collecting profile data. */
static VALUE
prof_pause(VALUE self)
{
    if (threads_tbl == NULL)
    {
        rb_raise(rb_eRuntimeError, "RubyProf is not running.");
    }

    prof_remove_hook();
    return self;
}

/* call-seq:
   resume {block} -> RubyProf
   
   Resumes recording profile data.*/
static VALUE
prof_resume(VALUE self)
{
    if (threads_tbl == NULL)
    { 
        prof_start(self);
    }
    else
    { 
        prof_install_hook();
    }
    
    if (rb_block_given_p())
    {
      rb_ensure(rb_yield, self, prof_pause, self);
    }

    return self;
}

/* call-seq:
   stop -> RubyProf::Result

   Stops collecting profile data and returns a RubyProf::Result object. */
static VALUE
prof_stop(VALUE self)
{
    VALUE result = Qnil;
    
    prof_remove_hook();

    prof_pop_threads();

    /* Create the result */
    result = prof_result_new();

    /* Unset the last_thread_data (very important!) 
       and the threads table */
    last_thread_data = NULL;
    threads_table_free(threads_tbl);
    threads_tbl = NULL;

    return result;
}

/* call-seq:
   profile {block} -> RubyProf::Result

Profiles the specified block and returns a RubyProf::Result object. */
static VALUE
prof_profile(VALUE self)
{
    int result;
    
    if (!rb_block_given_p())
    {
        rb_raise(rb_eArgError, "A block must be provided to the profile method.");
    }

    prof_start(self);
    rb_protect(rb_yield, self, &result);
    return prof_stop(self);
}

/* Get arround annoying limitations in RDOC */

/* Document-method: measure_process_time
   call-seq:
     measure_process_time -> float

Returns the process time.*/

/* Document-method: measure_wall_time
   call-seq:
     measure_wall_time -> float

Returns the wall time.*/

/* Document-method: measure_cpu_time
   call-seq:
     measure_cpu_time -> float

Returns the cpu time.*/

/* Document-method: get_cpu_frequency
   call-seq:
     cpu_frequency -> int

Returns the cpu's frequency.  This value is needed when 
RubyProf::measure_mode is set to CPU_TIME. */

/* Document-method: cpu_frequency
   call-seq:
     cpu_frequency -> int

Returns the cpu's frequency.  This value is needed when 
RubyProf::measure_mode is set to CPU_TIME. */

/* Document-method: cpu_frequency=
   call-seq:
     cpu_frequency = frequency

Sets the cpu's frequency.  This value is needed when 
RubyProf::measure_mode is set to CPU_TIME. */

/* Document-method: measure_allocations
   call-seq:
     measure_allocations -> int

Returns the total number of object allocations since Ruby started.*/

/* Document-method: measure_memory
   call-seq:
     measure_memory -> int

Returns total allocated memory in bytes.*/

/* Document-method: measure_gc_runs
   call-seq:
     gc_runs -> Integer

Returns the total number of garbage collections.*/

/* Document-method: measure_gc_time
   call-seq:
     gc_time -> Integer

Returns the time spent doing garbage collections in microseconds.*/


#if defined(_WIN32)
__declspec(dllexport) 
#endif
void

Init_ruby_prof()
{
    mProf = rb_define_module("RubyProf");
    rb_define_const(mProf, "VERSION", rb_str_new2(RUBY_PROF_VERSION));
    rb_define_module_function(mProf, "start", prof_start, 0);
    rb_define_module_function(mProf, "stop", prof_stop, 0);
    rb_define_module_function(mProf, "resume", prof_resume, 0);
    rb_define_module_function(mProf, "pause", prof_pause, 0);
    rb_define_module_function(mProf, "running?", prof_running, 0);
    rb_define_module_function(mProf, "profile", prof_profile, 0);
    
    rb_define_singleton_method(mProf, "exclude_threads=", prof_set_exclude_threads, 1);
    rb_define_singleton_method(mProf, "measure_mode", prof_get_measure_mode, 0);
    rb_define_singleton_method(mProf, "measure_mode=", prof_set_measure_mode, 1);

    rb_define_const(mProf, "CLOCKS_PER_SEC", INT2NUM(CLOCKS_PER_SEC));
    rb_define_const(mProf, "PROCESS_TIME", INT2NUM(MEASURE_PROCESS_TIME));
    rb_define_singleton_method(mProf, "measure_process_time", prof_measure_process_time, 0); /* in measure_process_time.h */
    rb_define_const(mProf, "WALL_TIME", INT2NUM(MEASURE_WALL_TIME));
    rb_define_singleton_method(mProf, "measure_wall_time", prof_measure_wall_time, 0); /* in measure_wall_time.h */

    #ifndef MEASURE_CPU_TIME
    rb_define_const(mProf, "CPU_TIME", Qnil);
    #else
    rb_define_const(mProf, "CPU_TIME", INT2NUM(MEASURE_CPU_TIME));
    rb_define_singleton_method(mProf, "measure_cpu_time", prof_measure_cpu_time, 0); /* in measure_cpu_time.h */
    rb_define_singleton_method(mProf, "cpu_frequency", prof_get_cpu_frequency, 0); /* in measure_cpu_time.h */
    rb_define_singleton_method(mProf, "cpu_frequency=", prof_set_cpu_frequency, 1); /* in measure_cpu_time.h */
    #endif
        
    #ifndef MEASURE_ALLOCATIONS
    rb_define_const(mProf, "ALLOCATIONS", Qnil);
    #else
    rb_define_const(mProf, "ALLOCATIONS", INT2NUM(MEASURE_ALLOCATIONS));
    rb_define_singleton_method(mProf, "measure_allocations", prof_measure_allocations, 0); /* in measure_allocations.h */
    #endif
    
    #ifndef MEASURE_MEMORY
    rb_define_const(mProf, "MEMORY", Qnil);
    #else
    rb_define_const(mProf, "MEMORY", INT2NUM(MEASURE_MEMORY));
    rb_define_singleton_method(mProf, "measure_memory", prof_measure_memory, 0); /* in measure_memory.h */
    #endif

    #ifndef MEASURE_GC_RUNS
    rb_define_const(mProf, "GC_RUNS", Qnil);
    #else
    rb_define_const(mProf, "GC_RUNS", INT2NUM(MEASURE_GC_RUNS));
    rb_define_singleton_method(mProf, "measure_gc_runs", prof_measure_gc_runs, 0); /* in measure_gc_runs.h */
    #endif

    #ifndef MEASURE_GC_TIME
    rb_define_const(mProf, "GC_TIME", Qnil);
    #else
    rb_define_const(mProf, "GC_TIME", INT2NUM(MEASURE_GC_TIME));
    rb_define_singleton_method(mProf, "measure_gc_time", prof_measure_gc_time, 0); /* in measure_gc_time.h */
    #endif

    cResult = rb_define_class_under(mProf, "Result", rb_cObject);
    rb_undef_method(CLASS_OF(cMethodInfo), "new");
    rb_define_method(cResult, "threads", prof_result_threads, 0);

    /* MethodInfo */
    cMethodInfo = rb_define_class_under(mProf, "MethodInfo", rb_cObject);
    rb_undef_method(CLASS_OF(cMethodInfo), "new");
    
    rb_define_method(cMethodInfo, "klass", prof_method_klass, 0);
    rb_define_method(cMethodInfo, "klass_name", prof_klass_name, 0);
    rb_define_method(cMethodInfo, "method_name", prof_method_name, 0);
    rb_define_method(cMethodInfo, "full_name", prof_full_name, 0);
    rb_define_method(cMethodInfo, "method_id", prof_method_id, 0);
    
    rb_define_method(cMethodInfo, "source_file", prof_method_source_file,0);
    rb_define_method(cMethodInfo, "line", prof_method_line, 0);

    rb_define_method(cMethodInfo, "call_infos", prof_method_call_infos, 0);

    /* CallInfo */
    cCallInfo = rb_define_class_under(mProf, "CallInfo", rb_cObject);
    rb_undef_method(CLASS_OF(cCallInfo), "new");
    rb_define_method(cCallInfo, "parent", prof_call_info_parent, 0);
    rb_define_method(cCallInfo, "children", prof_call_info_children, 0);
    rb_define_method(cCallInfo, "target", prof_call_info_target, 0);
    rb_define_method(cCallInfo, "called", prof_call_info_called, 0);
    rb_define_method(cCallInfo, "total_time", prof_call_info_total_time, 0);
    rb_define_method(cCallInfo, "self_time", prof_call_info_self_time, 0);
    rb_define_method(cCallInfo, "wait_time", prof_call_info_wait_time, 0);
    rb_define_method(cCallInfo, "line", prof_call_info_line, 0);
}
