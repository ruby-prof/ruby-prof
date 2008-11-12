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

/* #define DEBUG */

#ifndef RUBY_PROF_H
#define RUBY_PROF_H

#include <stdio.h>

#include <ruby.h>

#ifndef RUBY_VM
#include <node.h>
#include <st.h>
typedef rb_event_t rb_event_flag_t;
#define rb_sourcefile() (node ? node->nd_file : 0)
#define rb_sourceline() (node ? nd_line(node) : 0)
#endif

#include "version.h"

/* ================  Constants  =================*/
#define INITIAL_STACK_SIZE 8
#define INITIAL_CALL_INFOS_SIZE 2


/* ================  Measurement  =================*/
#ifdef HAVE_LONG_LONG
typedef unsigned LONG_LONG prof_measure_t;
#else
typedef unsigned long prof_measure_t;
#endif

#include "measure_process_time.h"
#include "measure_wall_time.h"
#include "measure_cpu_time.h"
#include "measure_allocations.h"
#include "measure_memory.h"
#include "measure_gc_runs.h"
#include "measure_gc_time.h"

static prof_measure_t (*get_measurement)() = measure_process_time;
static double (*convert_measurement)(prof_measure_t) = convert_process_time;

/* ================  DataTypes  =================*/
static VALUE mProf;
static VALUE cResult;
static VALUE cMethodInfo;
static VALUE cCallInfo;

/* Profiling information for each method. */
typedef struct {
    VALUE klass;                            /* The method's class. */
    ID mid;                                 /* The method id. */
    int depth;                              /* The recursion depth. */
    int key;                                /* Cache calculated key */
} prof_method_key_t;

struct prof_call_infos_t;

/* Profiling information for each method. */
typedef struct {
    prof_method_key_t *key;                 /* Method key */
    const char *source_file;                /* The method's source file */
    int line;                               /* The method's line number. */
    int active;                             /* Is this  recursion depth. */
    struct prof_call_infos_t *call_infos;   /* Call info objects for this method */
    VALUE object;                           /* Cahced ruby object */
} prof_method_t;

/* Callers and callee information for a method. */
typedef struct prof_call_info_t {
    prof_method_t *target; /* Use target instead of method to avoid conflict with Ruby method */
    struct prof_call_info_t *parent;
    st_table *call_infos;
    int called;
    prof_measure_t total_time;
    prof_measure_t self_time;
    prof_measure_t wait_time;
    int line;  
    VALUE object;
    VALUE children;
} prof_call_info_t;

/* Array of call_info objects */
typedef struct prof_call_infos_t {
    prof_call_info_t **start;
    prof_call_info_t **end;
    prof_call_info_t **ptr;
    VALUE object;
} prof_call_infos_t;


/* Temporary object that maintains profiling information
   for active methods - there is one per method.*/
typedef struct {
    /* Caching prof_method_t values significantly
       increases performance. */
    prof_call_info_t *call_info;
    prof_measure_t start_time;
    prof_measure_t wait_time;
    prof_measure_t child_time;
    unsigned int line;
} prof_frame_t;

/* Current stack of active methods.*/
typedef struct {
    prof_frame_t *start;
    prof_frame_t *end;
    prof_frame_t *ptr;
} prof_stack_t;

/* Profiling information for a thread. */
typedef struct {
    VALUE thread_id;                  /* Thread id */
    st_table* method_table;           /* Methods called in the thread */
    prof_stack_t* stack;              /* Active methods */
    prof_measure_t last_switch;       /* Point of last context switch */
} thread_data_t;

typedef struct {
    VALUE threads;
} prof_result_t;


/* ================  Variables  =================*/
static int measure_mode;
static st_table *threads_tbl = NULL;
static st_table *exclude_threads_tbl = NULL;

/* TODO - If Ruby become multi-threaded this has to turn into
   a separate stack since this isn't thread safe! */
static thread_data_t* last_thread_data = NULL;


/* Forward declarations */
static VALUE prof_call_infos_wrap(prof_call_infos_t *call_infos);
static VALUE prof_call_info_wrap(prof_call_info_t *call_info);
static VALUE prof_method_wrap(prof_method_t *result);

#endif
