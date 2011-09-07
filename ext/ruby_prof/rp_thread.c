/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "ruby_prof.h"

/* ======   thread_data_t  ====== */
thread_data_t*
thread_data_create()
{
    thread_data_t* result = ALLOC(thread_data_t);
    result->stack = stack_create();
    result->method_table = method_table_create();
    result->last_switch = get_measurement();
    return result;
}

void
thread_data_free(thread_data_t* thread_data)
{
    method_table_free(thread_data->method_table);
    stack_free(thread_data->stack);
    xfree(thread_data);
}


/* ======   Thread Table  ====== */
/* The thread table is hash keyed on ruby thread_id that stores instances
   of thread_data_t. */

st_table *
threads_table_create()
{
    return st_init_numtable();
}

size_t
threads_table_insert(st_table *table, VALUE thread, thread_data_t *thread_data)
{
    /* Its too slow to key on the real thread id so just typecast thread instead. */
    return st_insert(table, (st_data_t) thread, (st_data_t) thread_data);
}

thread_data_t *
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
        threads_table_insert(table, thread_id, result);
    }
    return result;
}

int
free_thread_data(st_data_t key, st_data_t value, st_data_t dummy)
{
    thread_data_free((thread_data_t*)value);
    return ST_CONTINUE;
}

void
threads_table_free(st_table *table)
{
    st_foreach(table, free_thread_data, 0);
    st_free_table(table);
}
