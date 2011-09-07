/* Copyright (C) 2005-2011 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_PROF_H__
#define __RUBY_PROF_H__

#include <stdio.h>
#include <ruby.h>

#if RUBY_VERSION == 186
# error 1.8.6 is not supported.  Please upgrade to 1.8.7 or 1.9.2 or higher.
#endif

#if RUBY_VERSION == 190
# error 1.9.0 is not supported.  Please upgrade to 1.9.2 or higher.
#endif

#if RUBY_VERSION == 191
# error 1.9.1 is not supported.  Please upgrade to 1.9.2 or higher.
#endif


#ifndef RUBY_VM
#include <node.h>
#include <st.h>
typedef rb_event_t rb_event_flag_t;
#define rb_sourcefile() (node ? node->nd_file : 0)
#define rb_sourceline() (node ? nd_line(node) : 0)
#endif

#include "version.h"

/* nasty hack to avoid compilation warnings related to 64/32 bit conversions */
#ifndef SIZEOF_ST_INDEX_T
#define st_index_t int
#endif

#include "rp_measurement.h"
#include "rp_method_info.h"
#include "rp_call_info.h"
#include "rp_stack.h"
#include "rp_thread.h"
#include "rp_result.h"

VALUE mProf;
void method_key(prof_method_key_t* key, VALUE klass, ID mid);

#endif //__RUBY_PROF_H__
