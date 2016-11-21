/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_CALL_INFO_H__
#define __RP_CALL_INFO_H__

#include "rp_measure.h"
#include "rp_method.h"

extern VALUE cCallInfo;

typedef struct prof_measure_value_t
{
    double total;
    double self;
    double wait;
} prof_measure_value_t;

/* Callers and callee information for a method. */
typedef struct prof_call_info_t
{
    prof_method_t *target; /* Use target instead of method to avoid conflict with Ruby method */
    struct prof_call_info_t *parent;
    st_table *call_infos;

    VALUE object;
    VALUE children;

    int called;

    unsigned int recursive : 1;
    unsigned int depth : 15;
    unsigned int line : 16;

    size_t measures_len;
    prof_measure_value_t measure_values[];
} prof_call_info_t;

/* Array of call_info objects */
typedef struct prof_call_infos_t
{
    prof_call_info_t **start;
    prof_call_info_t **end;
    prof_call_info_t **ptr;
    VALUE object;
} prof_call_infos_t;


void rp_init_call_info(void);
prof_call_infos_t* prof_call_infos_create();
void prof_call_infos_mark(prof_call_infos_t *call_infos);
void prof_call_infos_free(prof_call_infos_t *call_infos);
void prof_add_call_info(prof_call_infos_t *call_infos, prof_call_info_t *call_info);
VALUE prof_call_infos_wrap(prof_call_infos_t *call_infos);
prof_call_info_t * prof_call_info_create(prof_method_t* method, prof_call_info_t* parent, size_t measurements_len);
prof_call_info_t * call_info_table_lookup(st_table *table, const prof_method_key_t *key);
size_t call_info_table_insert(st_table *table, const prof_method_key_t *key, prof_call_info_t *val);

#endif //__RP_CALL_INFO_H__
