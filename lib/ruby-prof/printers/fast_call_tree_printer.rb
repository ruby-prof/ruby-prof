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
      @event_specification = "events: "
      case RubyProf.measure_mode
        when RubyProf::PROCESS_TIME
          @value_scale = RubyProf::CLOCKS_PER_SEC
          @event_specification << 'process_time'
        when RubyProf::WALL_TIME
          @value_scale = 1_000_000
          @event_specification << 'wall_time'
        when RubyProf.const_defined?(:CPU_TIME) && RubyProf::CPU_TIME
          @value_scale = RubyProf.cpu_frequency
          @event_specification << 'cpu_time'
        when RubyProf.const_defined?(:ALLOCATIONS) && RubyProf::ALLOCATIONS
          @value_scale = 1
          @event_specification << 'allocations'
        when RubyProf.const_defined?(:MEMORY) && RubyProf::MEMORY
          @value_scale = 1
          @event_specification << 'memory'
        when RubyProf.const_defined?(:GC_RUNS) && RubyProf::GC_RUNS
          @value_scale = 1
          @event_specification << 'gc_runs'
        when RubyProf.const_defined?(:GC_TIME) && RubyProf::GC_TIME
          @value_scale = 1000000
          @event_specification << 'gc_time'
        else
          raise "Unknown measure mode: #{RubyProf.measure_mode}"
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

    def print_headers(output, thread)
      @output << "#{@event_specification}\n\n"
      # this doesn't work. kcachegrind does not fully support the spec.
      # output << "thread: #{thread.id}\n\n"
    end
  end # end class
end # end packages
