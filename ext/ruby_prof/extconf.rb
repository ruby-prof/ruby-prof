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

# 1.9.3 superclass
have_func("rb_class_superclass")

# Lloyd Hilaiel's heap info patch
have_func("rb_heap_total_mem")
have_func("rb_gc_heap_info")

# Ruby 1.9 unexposed methods
have_func("rb_gc_malloc_allocations")
have_func("rb_gc_malloc_allocated_size")

def add_define(name, value = nil)
  if value
    $defs.push("-D#{name}=#{value}")
  else
    $defs.push("-D#{name}")
  end
end
require 'rubygems'
unless Gem.win_platform? || RUBY_PLATFORM =~ /darwin/
  $LDFLAGS += " -lrt" # for clock_gettime
end
add_define("RUBY_VERSION", RUBY_VERSION.gsub('.', ''))

# for ruby 1.9, determine whether threads inherit trace flags (latest 1.9.2 works correctly)
if RUBY_VERSION > "1.9"
  require 'set'
  threads = Set.new
  set_trace_func lambda { |*args| threads << Thread.current.object_id }
  Thread.new{1}.join
  set_trace_func nil
  add_define("THREADS_INHERIT_EVENT_FLAGS", (threads.size == 2) ? "1" : "0")
end

create_makefile("ruby_prof")
