/* Copyright (C) 2005-2013 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_METHOD_INFO__
#define __RP_METHOD_INFO__

#include <ruby.h>

extern VALUE cMethodInfo;

/* A key used to identify each method */
typedef struct
{
    VALUE klass;                            /* The method's class. */
    ID mid;                                 /* The method id. */
    st_index_t key;                         /* Cache calculated key */
} prof_method_key_t;

/* Source relation bit offsets. */
enum {
    kModuleIncludee = 0,                    /* Included module */
    kModuleSingleton,                       /* Singleton class of a module */
    kObjectSingleton                        /* Singleton class of an object */
};

/* Forward declaration, see rp_call_info.h */
struct prof_call_infos_t;

/* Profiling information for each method. */
/* Excluded methods have no call_infos, source_klass, or source_file. */
typedef struct
{
    /* Hot */

    prof_method_key_t *key;                 /* Table key */

    struct prof_call_infos_t *call_infos;   /* Call infos */
    int visits;                             /* Current visits on the stack */

    unsigned int excluded : 1;              /* Exclude from profile? */
    unsigned int recursive : 1;             /* Recursive (direct or mutual)? */

    /* Cold */

    VALUE object;                           /* Cached ruby object */
    VALUE source_klass;                     /* Source class */
    const char *source_file;                /* Source file */
    int line;                               /* Line number */

    unsigned int resolved : 1;              /* Source resolved? */
    unsigned int relation : 3;              /* Source relation bits */
} prof_method_t;

void rp_init_method_info(void);

void method_key(prof_method_key_t* key, VALUE klass, ID mid);

st_table * method_table_create();
prof_method_t * method_table_lookup(st_table *table, const prof_method_key_t* key);
size_t method_table_insert(st_table *table, const prof_method_key_t *key, prof_method_t *val);
void method_table_free(st_table *table);

prof_method_t* prof_method_create(VALUE klass, ID mid, const char* source_file, int line);
prof_method_t* prof_method_create_excluded(VALUE klass, ID mid);

VALUE prof_method_wrap(prof_method_t *result);
void prof_method_mark(prof_method_t *method);

/* Setup infrastructure to use method keys as hash comparisons */
int method_table_cmp(prof_method_key_t *key1, prof_method_key_t *key2);
st_index_t method_table_hash(prof_method_key_t *key);

extern struct st_hash_type type_method_hash;

#endif
