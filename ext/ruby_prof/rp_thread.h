/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_THREAD__
#define __RP_THREAD__

/* Profiling information for a thread. */
typedef struct
{
    uintptr_t thread_index;           /* Thread index (main is 0) */
    VALUE thread_id;                  /* Thread id */
    VALUE fiber_id;                   /* Fiber id */

    st_table* method_table;           /* Methods called in the thread */
    prof_stack_t* stack;              /* Stack of frames */

    VALUE object;                     /* Cache to wrapped object */
    VALUE methods;                    /* Array of RubyProf::MethodInfo */
} thread_data_t;

void rp_init_thread();

st_table * threads_table_create();
void threads_table_free(st_table *table);

thread_data_t* switch_thread(void* prof, VALUE thread_id, VALUE fiber_id);

VALUE prof_thread_wrap(thread_data_t *thread);
void prof_thread_mark(thread_data_t *thread);

int pause_thread(st_data_t key, st_data_t value, st_data_t data);
int unpause_thread(st_data_t key, st_data_t value, st_data_t data);

#endif //__RP_THREAD__
