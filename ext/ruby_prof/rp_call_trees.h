/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#pragma once

#include "ruby_prof.h"
#include "rp_call_tree.h"

   /* Array of call_tree objects */
typedef struct prof_call_trees_t
{
    prof_call_tree_t** start;
    prof_call_tree_t** end;
    prof_call_tree_t** ptr;

    VALUE object;
} prof_call_trees_t;


void rp_init_call_trees(void);
prof_call_trees_t* prof_call_trees_create(void);
void prof_call_trees_free(prof_call_trees_t* call_trees);
prof_call_trees_t* prof_get_call_trees(VALUE self);
void prof_add_call_tree(prof_call_trees_t* call_trees, prof_call_tree_t* call_tree);
VALUE prof_call_trees_wrap(prof_call_trees_t* call_trees);
