require "mkmf"

if RUBY_VERSION >= "1.9"
  if RUBY_RELEASE_DATE < "2005-03-17"
    STDERR.print("Ruby version is too old\n")
    exit(1)
  end
elsif RUBY_VERSION >= "1.8"
  if RUBY_RELEASE_DATE < "2005-03-22"
    STDERR.print("Ruby version is too old\n")
    exit(1)
  end
else
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

have_header("sys/times.h")

# Stefan Kaes / Alexander Dymo GC patch
have_func("rb_os_allocated_objects")
have_func("rb_gc_allocated_size")
have_func("rb_gc_collections")
have_func("rb_gc_time")

# Lloyd Hilaiel's heap info patch
have_func("rb_heap_total_mem")
have_func("rb_gc_heap_info")

# Ruby 1.9 unexposed methods
have_func("rb_gc_malloc_allocations")
have_func("rb_gc_malloc_allocated_size")

def add_define(name)
  $defs.push("-D#{name}")
end

add_define 'DEBUG' if $DEBUG

if RUBY_VERSION >= '1.9'
 add_define 'RUBY_VM'
 require 'ruby_core_source'
 hdrs = proc { have_header("vm_core.h")  }
 if !Ruby_core_source::create_makefile_with_core(hdrs, "ruby_prof")
   # error
   exit(1)
 end
else
  create_makefile("ruby_prof")
end
