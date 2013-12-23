require "mkmf"

if RUBY_VERSION < "1.9.3"
  STDERR.puts("Ruby version #{RUBY_VERSION} is no longer supported. Please upgrade to 1.9.3 or higher")
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

# whether our ruby has fibers
have_func("rb_fiber_current")

def add_define(name, value = nil)
  if value
    $defs.push("-D#{name}=#{value}")
  else
    $defs.push("-D#{name}")
  end
end

# if have_func("rb_gc_enable_stats")
#   add_define("TOGGLE_GC_STATS", 1)
# end

if !Gem.win_platform? && RUBY_PLATFORM !~ /(darwin|openbsd)/
  $LDFLAGS += " -lrt" # for clock_gettime
end
add_define("RUBY_VERSION", RUBY_VERSION.gsub('.', ''))

# for ruby 1.9, determine whether threads inherit trace flags (latest 1.9.2 and later should work correctly)
if RUBY_VERSION > "1.9"
  require 'set'
  threads = Set.new
  set_trace_func lambda { |*args| threads << Thread.current.object_id }
  Thread.new{1}.join
  set_trace_func nil
  if threads.size < 2
    # if we end up here, ruby does not automatically active tracing in spawned threads
    STDERR.puts("Ruby #{RUBY_VERSION} does not activate tracing in spawned threads. Consider upgrading.")
    exit(1)
  end
end

create_makefile("ruby_prof")
