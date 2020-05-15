require "mkmf"

# This function was added in Ruby 2.5, so once Ruby 2.4 is no longer supported this can be removed
have_func('rb_tracearg_callee_id', ["ruby.h"])

# We want to intermix declarations and code (ie, don't define all variables at the top of the method)
$CFLAGS += ' -std=c99'

create_makefile("ruby_prof")
