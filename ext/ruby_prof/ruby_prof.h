/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_PROF_H__
#define __RUBY_PROF_H__

#include <ruby.h>
#include <stdio.h>
#include "rp_measure.h"
#include "rp_method.h"
#include "rp_call_info.h"
#include "rp_stack.h"
#include "rp_thread.h"

extern VALUE mProf;
extern VALUE cProfile;

typedef struct
{
    VALUE running;
    VALUE paused;

    prof_measurer_t* measurer;
    VALUE threads;

    st_table* threads_tbl;
    st_table* exclude_threads_tbl;
    st_table* include_threads_tbl;
    st_table* exclude_methods_tbl;
    thread_data_t* last_thread_data;
    double measurement_at_pause_resume;
    int allow_exceptions;
} prof_profile_t;

#endif //__RUBY_PROF_H__
