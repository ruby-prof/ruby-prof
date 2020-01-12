/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_AGGREGATE_CALL_TREE_H__
#define __RP_AGGREGATE_CALL_TREE_H__

#include "ruby_prof.h"
#include "rp_call_tree.h"

void rp_init_aggregate_call_tree(void);
VALUE prof_aggregate_call_tree_wrap(prof_call_tree_t* call_tree);

#endif //__RP_AGGREGATE_CALL_TREE_H__
