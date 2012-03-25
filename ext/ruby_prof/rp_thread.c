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
threads_table_insert(prof_profile_t* profile, VALUE thread, thread_data_t *thread_data)
{
    /* Its too slow to key on the real thread id so just typecast thread instead. */
    return st_insert(profile->threads_tbl, (st_data_t) thread, (st_data_t) thread_data);
}

thread_data_t *
threads_table_lookup(prof_profile_t* profile, VALUE thread_id)
{
    thread_data_t* result;
    st_data_t val;

    /* Its too slow to key on the real thread id so just typecast thread instead. */
    if (st_lookup(profile->threads_tbl, (st_data_t) thread_id, &val))
    {
      result = (thread_data_t *) val;
    }
    else
    {
        result = thread_data_create(profile->measurer->measure());
        result->thread_id = thread_id;

        /* Insert the table */
        threads_table_insert(profile, thread_id, result);
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

thread_data_t *
switch_thread(void* prof, VALUE thread_id)
{
	prof_profile_t* profile = (prof_profile_t*)prof;
    double measurement = profile->measurer->measure();

    /* Get new thread information. */
    thread_data_t *thread_data = threads_table_lookup(profile, thread_id);

    /* Get current frame for this thread */
    prof_frame_t *frame = stack_peek(thread_data->stack);

    /* Update the time this thread waited for another thread */
	if (frame)
	{
		frame->wait_time += measurement - frame->switch_time;
		frame->switch_time = measurement;
	}

    /* Save on the last thread the time of the context switch
       and reset this thread's last context switch to 0.*/
    if (profile->last_thread_data)
	{
       prof_frame_t *last_frame = stack_peek(profile->last_thread_data->stack);
	   if (last_frame)
		 last_frame->switch_time = measurement;
    }

    profile->last_thread_data = thread_data;
    return thread_data;
}
