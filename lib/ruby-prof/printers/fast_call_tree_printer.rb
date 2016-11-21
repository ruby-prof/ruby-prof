# encoding: utf-8

require 'fiber'
require 'thread'
require 'fileutils'

module RubyProf
  # Optimized implementation of CallTreePrinter
  class FastCallTreePrinter
    def initialize(result)
      @result = result
      @output = nil
    end

    # Specify print options.
    #
    # options - Hash table
    #
    #   :only_threads - list of threads to print
    def print(output = STDOUT, options = {})
      @output = output
      @options = options

      determine_event_specification_and_value_scale
      print_headers
      print_threads
    end

    def determine_event_specification_and_value_scale
      @value_scales = []
      @event_specifications = ['events:']

      @result.measure_modes.each do |measure_mode|
        case measure_mode
          when RubyProf::PROCESS_TIME
            @value_scales << RubyProf::CLOCKS_PER_SEC
            @event_specifications << 'process_time'
          when RubyProf::WALL_TIME
            @value_scales << 1_000_000
            @event_specifications << 'wall_time'
          when RubyProf.const_defined?(:CPU_TIME) && RubyProf::CPU_TIME
            @value_scales << RubyProf.cpu_frequency
            @event_specifications << 'cpu_time'
          when RubyProf.const_defined?(:ALLOCATIONS) && RubyProf::ALLOCATIONS
            @value_scales << 1
            @event_specifications << 'allocations'
          when RubyProf.const_defined?(:MEMORY) && RubyProf::MEMORY
            @value_scales << 1
            @event_specifications << 'memory'
          when RubyProf.const_defined?(:GC_RUNS) && RubyProf::GC_RUNS
            @value_scales << 1
            @event_specifications << 'gc_runs'
          when RubyProf.const_defined?(:GC_TIME) && RubyProf::GC_TIME
            @value_scales << 1000000
            @event_specifications << 'gc_time'
          else
            raise "Unknown measure mode: #{measure_mode}"
        end
      end
    end

    def print_threads
      # TODO: merge fibers of a given thread here, instead of relying
      # on the profiler to merge fibers.
      printable_threads.each do |thread|
        print_thread(thread)
      end
    end

    def printable_threads
      if @options[:only_threads]
        only_thread_ids = @options[:only_threads].map(&:object_id)
        @result.threads.select do |t|
          only_thread_ids.include?(t.id)
        end
      else
        @result.threads
      end
    end

    def print_headers
      @output << "#{@event_specifications.join(" ")}\n\n"
      # this doesn't work. kcachegrind does not fully support the spec.
      # output << "thread: #{thread.id}\n\n"
    end
  end # end class
end # end packages
