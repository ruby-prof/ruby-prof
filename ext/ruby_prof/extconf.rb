require "mkmf"

# This function was added in Ruby 2.5, so once Ruby 2.4 is no longer supported this can be removed
have_func('rb_tracearg_callee_id', ["ruby.h"])

# Let's go with a modern version of C! want to intermix declarations and code (ie, don't define
# all variables at the top of the method). If using Visual Studio, you'll need 2019 version
# 16.8 or higher
if RUBY_PLATFORM =~ /mswin/
  $CFLAGS += ' /std:c11'
else
  $CFLAGS += ' -std=c11'
end

# And since we are using C99 we want to disable Ruby sending these warnings to gcc
if CONFIG['warnflags']
  CONFIG['warnflags'].gsub!('-Wdeclaration-after-statement', '')
end

create_makefile("ruby_prof")
