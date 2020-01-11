/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_CALL_INFOS_H__
#define __RP_CALL_INFOS_H__

#include "ruby_prof.h"
#include "rp_call_info.h"

/* Array of call_info objects */
typedef struct prof_call_infos_t
{
    prof_call_info_t** start;
    prof_call_info_t** end;
    prof_call_info_t** ptr;

    VALUE object;
} prof_call_infos_t;


prof_call_infos_t* prof_call_infos_create();
void prof_call_infos_mark(prof_call_infos_t *call_infos);
void prof_call_infos_free(prof_call_infos_t *call_infos);
prof_call_infos_t* prof_get_call_infos(VALUE self);
void prof_add_call_info(prof_call_infos_t* call_infos, prof_call_info_t* call_info);
VALUE prof_call_infos_wrap(prof_call_infos_t *call_infos);

#endif //__RP_CALL_INFOS_H__
