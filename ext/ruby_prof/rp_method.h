/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_METHOD_INFO__
#define __RP_METHOD_INFO__

#include "ruby_prof.h"
#include "rp_measurement.h"

extern VALUE cRpMethodInfo;

/* Source relation bit offsets. */
enum {
    kModuleIncludee = 0x1,                    /* Included in module */
    kClassSingleton = 0x2,                    /* Singleton of a class */
    kModuleSingleton = 0x4,                   /* Singleton of a module */
    kObjectSingleton = 0x8,                   /* Singleton of an object */
    kOtherSingleton = 0x10                    /* Singleton of unkown object */
};

/* Profiling information for each method. */
/* Excluded methods have no call_infos, source_klass, or source_file. */
typedef struct
{
    st_data_t key;                          /* Table key */

    int visits;                             /* Current visits on the stack */
    bool excluded;                          /* Exclude from profile? */

    struct prof_call_infos_t* call_infos;   /* Call infos that call this method */
    st_table* allocations_table;            /* Tracks object allocations */

    unsigned int klass_flags;               /* Information about the type of class */
    VALUE klass;                            /* Resolved klass */
    VALUE klass_name;                       /* Resolved klass name for this method */
    VALUE method_name;                      /* Resolved method name for this method */

    VALUE object;                           /* Cached ruby object */

    bool recursive;
    VALUE source_file;                       /* Source file */
    int source_line;                         /* Line number */

    prof_measurement_t* measurement;
} prof_method_t;

void rp_init_method_info(void);

st_data_t method_key(VALUE klass, VALUE msym);

st_table* method_table_create(void);
prof_method_t* prof_method_create_excluded(VALUE klass, VALUE msym);
prof_method_t* method_table_lookup(st_table* table, st_data_t key);
size_t method_table_insert(st_table* table, st_data_t key, prof_method_t* val);
void method_table_free(st_table* table);
prof_method_t* prof_method_create(VALUE klass, VALUE msym, VALUE source_file, int source_line);
prof_method_t* prof_method_get(VALUE self);

VALUE prof_method_wrap(prof_method_t* result);
void prof_method_mark(void* data);

VALUE resolve_klass(VALUE klass, unsigned int* klass_flags);
VALUE resolve_klass_name(VALUE klass, unsigned int* klass_flags);

#endif //__RP_METHOD_INFO__
