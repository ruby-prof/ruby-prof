/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_PROF_H__
#define __RUBY_PROF_H__

#include <ruby.h>
#include <ruby/debug.h>
#include <stdio.h>
#include <stdbool.h>

extern VALUE mProf;

// This method is not exposed in Ruby header files - at least not as of Ruby 2.6.3 :(
extern size_t rb_obj_memsize_of(VALUE);

#endif //__RUBY_PROF_H__
