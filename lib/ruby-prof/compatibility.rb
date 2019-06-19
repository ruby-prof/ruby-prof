# encoding: utf-8

# These methods are here for backwards compatability with previous RubyProf releases
module RubyProf
  # call-seq:
  # measure_mode -> measure_mode
  #
  # Returns what ruby-prof is measuring.  Valid values include:
  #
  # *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows.  This is default.
  # *RubyProf::PROCESS_TIME - Measure process time.  It is implemented using the clock functions in the C Runtime library.
  # *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms.
  # *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
  # *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
  # *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
  # *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/

  def self.measure_mode
    @measure_mode ||= RubyProf::WALL_TIME
  end

  # call-seq:
  # measure_mode=value -> void
  #
  # Specifies what ruby-prof should measure.  Valid values include:
  #
  # *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows.  This is default.
  # *RubyProf::PROCESS_TIME - Measure process time.  It is implemented using the clock functions in the C Runtime library.
  # *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms.
  # *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
  # *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
  # *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
  # *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/
  def self.measure_mode=(value)
    @measure_mode = value
  end

  def self.measure_mode_string
    case measure_mode
    when WALL_TIME    then "wall_time"
    when PROCESS_TIME then "process_time_time"
    when ALLOCATIONS  then "allocations"
    when MEMORY       then "memory"
    when GC_TIME      then "gc_time"
    when GC_RUNS      then "gc_runs"
    end
  end

  # call-seq:
  # exclude_threads -> exclude_threads
  #
  # Returns threads ruby-prof should exclude from profiling

  def self.exclude_threads
    @exclude_threads ||= Array.new
  end

  # call-seq:
  # exclude_threads= -> void
  #
  # Specifies what threads ruby-prof should exclude from profiling

  def self.exclude_threads=(value)
    @exclude_threads = value
  end

  # Profiling
  def self.start_script(script)
    start
    load script
  end

  def self.start
    ensure_not_running!
    @profile = Profile.new(measure_mode: measure_mode, exclude_threads: exclude_threads)
    enable_gc_stats_if_needed
    @profile.start
  end

  def self.pause
    ensure_running!
    disable_gc_stats_if_needed
    @profile.pause
  end

  def self.running?
    if defined?(@profile) and @profile
      @profile.running?
    else
      false
    end
  end

  def self.resume
    ensure_running!
    @profile.resume
  end

  def self.stop
    ensure_running!
    result = @profile.stop
    @profile = nil
    result
  end

  # Profile a block
  def self.profile(options = {}, &block)
    ensure_not_running!
    options = {measure_mode: measure_mode, exclude_threads: exclude_threads }.merge!(options)
    Profile.new(options, &block)
  end

private

  def self.ensure_running!
    raise(RuntimeError, "RubyProf.start was not yet called") unless running?
  end

  def self.ensure_not_running!
    raise(RuntimeError, "RubyProf is already running") if running?
  end
end
