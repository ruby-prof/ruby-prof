/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_THREAD__
#define __RP_THREAD__

/* Profiling information for a thread. */
typedef struct {
    VALUE thread_id;                  /* Thread id */
    st_table* method_table;           /* Methods called in the thread */
    prof_stack_t* stack;              /* Active methods */
    double last_switch;       /* Point of last context switch */
} thread_data_t;

st_table * threads_table_create();
size_t threads_table_insert(st_table *table, VALUE thread, thread_data_t *thread_data);
thread_data_t * threads_table_lookup(st_table *table, VALUE thread_id);
void threads_table_free(st_table *table);

#endif //__RP_THREAD__
