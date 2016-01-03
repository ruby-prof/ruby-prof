# encoding: utf-8

module RubyProf
  # Generate profiling information in calltree format
  # for use by kcachegrind and similar tools.

  class CallTreePrinter  < AbstractPrinter
    # Specify print options.
    #
    # options - Hash table
    #   :min_percent - Number 0 to 100 that specifes the minimum
    #                  %self (the methods self time divided by the
    #                  overall total time) that a method must take
    #                  for it to be printed out in the report.
    #                  Default value is 0.
    #
    #   :print_file  - True or false. Specifies if a method's source
    #                  file should be printed.  Default value if false.
    #
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)
      determine_event_specification_and_value_scale
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
      # TODO: merge fibers of a given thread
      # kcachegrind doesn't know about fibers
      @result.threads.each do |thread|
        print_thread(thread)
      end
    end

    def convert(value)
      (value * @value_scale).round
    end

    def file(method)
      File.expand_path(method.source_file)
    end

    def print_thread(thread)
      print_headers(thread)
      thread.methods.reverse_each do |method|
        print_method(method)
      end
    end

    def print_headers(thread)
      @output << "#{@event_specification}\n"
      @output << "thread: #{thread.id}\n\n"
    end

    def print_method(method)
      # Print out the file and method name
      @output << "fl=#{file(method)}\n"
      @output << "fn=#{method_name(method)}\n"

      # Now print out the function line number and its self time
      @output << "#{method.line} #{convert(method.self_time)}\n"

      # Now print out all the children methods
      method.children.each do |callee|
        @output << "cfl=#{file(callee.target)}\n"
        @output << "cfn=#{method_name(callee.target)}\n"
        @output << "calls=#{callee.called} #{callee.line}\n"

        # Print out total times here!
        @output << "#{callee.line} #{convert(callee.total_time)}\n"
      end
      @output << "\n"
    end
  end
end
