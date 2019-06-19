/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_PROF_H__
#define __RUBY_PROF_H__

#include <ruby.h>
#include <ruby/debug.h>
#include <stdio.h>
#include <stdbool.h>

extern VALUE mProf;

#ifndef rb_obj_memsize_of
extern size_t rb_obj_memsize_of(VALUE);
#endif

#endif //__RUBY_PROF_H__
