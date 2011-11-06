/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_RESULT__
#define __RP_RESULT__

#include "ruby_prof.h"

extern VALUE cResult;

typedef struct 
{
    VALUE threads;
} prof_result_t;

void rp_init_result();
VALUE prof_result_new(st_table* threads_tbl);


#endif //__RP_RESULT__
