/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#include "rp_call_infos.h"

#define INITIAL_CALL_INFOS_SIZE 2

/* =======  Call Infos   ========*/
prof_call_infos_t*
prof_call_infos_create()
{
   prof_call_infos_t *result = ALLOC(prof_call_infos_t);
   result->start = ALLOC_N(prof_call_info_t*, INITIAL_CALL_INFOS_SIZE);
   result->end = result->start + INITIAL_CALL_INFOS_SIZE;
   result->ptr = result->start;
   result->object = Qnil;
   return result;
}

void
prof_call_infos_mark(prof_call_infos_t *call_infos)
{
    prof_call_info_t **call_info;

	if (call_infos->object)
		rb_gc_mark(call_infos->object);

    for(call_info=call_infos->start; call_info<call_infos->ptr; call_info++)
    {
		prof_call_info_mark(*call_info);
    }
}

void
prof_call_infos_free(prof_call_infos_t *call_infos)
{
    prof_call_info_t **call_info;

    for(call_info=call_infos->start; call_info<call_infos->ptr; call_info++)
    {
		prof_call_info_free(*call_info);
    }
    xfree(call_infos);
}

void
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

VALUE
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

void rp_init_call_infos()
{
}
