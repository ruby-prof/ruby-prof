# encoding: utf-8

# These methods are here for backwards compatability with previous RubyProf releases
module RubyProf
  # Measurements
  def self.cpu_frequency
    Measure::CpuTime.frequency
  end

  def self.cpu_frequency=(value)
    Measure::CpuTime.frequency = value
  end

  def self.measure_allocations
    Measure::Allocations.measure
  end

  def self.measure_cpu_time
    Measure::CpuTime.measure
  end
  
  def self.measure_gc_runs
    Measure::GcRuns.measure
  end

  def self.measure_gc_time
    Measure::GcTime.measure
  end

  def self.measure_memory
    Measure::Memory.measure
  end

  def self.measure_process_time
    Measure::ProcessTime.measure
  end

  def self.measure_wall_time
    Measure::WallTime.measure
  end
  
  # call-seq:
  # measure_mode -> measure_mode
  #
  # Returns what ruby-prof is measuring.  Valid values include:
  #
  # *RubyProf::PROCESS_TIME - Measure process time.  This is default.  It is implemented using the clock functions in the C Runtime library.
  # *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows
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
  # *RubyProf::PROCESS_TIME - Measure process time.  This is default.  It is implemented using the clock functions in the C Runtime library.
  # *RubyProf::WALL_TIME - Measure wall time using gettimeofday on Linx and GetLocalTime on Windows
  # *RubyProf::CPU_TIME - Measure time using the CPU clock counter.  This mode is only supported on Pentium or PowerPC platforms.
  # *RubyProf::ALLOCATIONS - Measure object allocations.  This requires a patched Ruby interpreter.
  # *RubyProf::MEMORY - Measure memory size.  This requires a patched Ruby interpreter.
  # *RubyProf::GC_RUNS - Measure number of garbage collections.  This requires a patched Ruby interpreter.
  # *RubyProf::GC_TIME - Measure time spent doing garbage collection.  This requires a patched Ruby interpreter.*/
  def self.measure_mode=(value)
    @measure_mode = value
  end
  
  # call-seq:
  # exclude_threads= -> void
  #
  # Specifies what threads ruby-prof should exclude from profiling
  
  def self.exclude_threads
    @exclude_threads ||= Hash.new
  end
  
  def self.exclude_threads=(value)
    @exclude_threads = value
  end
  
  # Profiling
  def self.start
    if @profile
      raise(RuntimeError, "RubyProf is already running");
    end
    @profile = Profile.new(self.measure_mode, self.exclude_threads)
    @profile.start
  end

  def self.pause
    unless @profile
      raise(RuntimeError, "RubyProf.start was not yet called");
    end
    @profile.pause
  end

  def self.running?
    if @profile
      @profile.running?
    else
      false
    end
  end

  def self.resume
    unless @profile
      raise(RuntimeError, "RubyProf.start was not yet called");
    end
    @profile.resume
  end

  def self.stop
    unless @profile
      raise(RuntimeError, "RubyProf.start was not yet called");
    end
    result = @profile.stop
    @profile = nil
    result
  end

  def self.profile(&block)
    if @profile
      raise(RuntimeError, "RubyProf is already running");
    end
    Profile.profile(self.measure_mode, self.exclude_threads, &block)
  end
end