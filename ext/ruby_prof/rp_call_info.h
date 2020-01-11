/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_CALL_INFO_H__
#define __RP_CALL_INFO_H__

#include "ruby_prof.h"
#include "rp_measurement.h"
#include "rp_method.h"

   /* Callers and callee information for a method. */
typedef struct prof_call_info_t
{
    prof_method_t* method;
    struct prof_call_info_t* parent;
    st_table* children;             /* Call infos that this call info calls */
    prof_measurement_t* measurement;
    VALUE object;

    int visits;                             /* Current visits on the stack */

    unsigned int depth;
    unsigned int source_line;
    VALUE source_file;
} prof_call_info_t;

prof_call_info_t* prof_call_info_create(prof_method_t* method, prof_call_info_t* parent, VALUE source_file, int source_line);
prof_call_info_t* prof_call_info_copy(prof_call_info_t* other);
void prof_call_info_merge(prof_call_info_t* result, prof_call_info_t* other);
void prof_call_info_mark(void* data);
prof_call_info_t* call_info_table_lookup(st_table* table, st_data_t key);
size_t call_info_table_insert(st_table* table, st_data_t key, prof_call_info_t* val);
prof_call_info_t* prof_get_call_info(VALUE self);
VALUE prof_call_info_wrap(prof_call_info_t* call_info);
void prof_call_info_free(prof_call_info_t* call_info);
void rp_init_call_info(void);

#endif //__RP_CALL_INFO_H__
