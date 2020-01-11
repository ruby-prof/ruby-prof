/* Copyright (C) 2005-2019 Shugo Maeda <shugo@ruby-lang.org> and Charlie Savage <cfis@savagexi.com>
   Please see the LICENSE file for copyright and distribution information */

#ifndef __RP_AGGREGATE_CALL_INFO_H__
#define __RP_AGGREGATE_CALL_INFO_H__

#include "ruby_prof.h"
#include "rp_call_info.h"

void rp_init_aggregate_call_info(void);
VALUE prof_aggregate_call_info_wrap(prof_call_info_t* call_info);

#endif //__RP_AGGREGATE_CALL_INFO_H__
