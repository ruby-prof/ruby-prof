require 'ruby-prof/abstract_printer'

module RubyProf
  # Generate profiling information in calltree format
  # for use by kcachegrind and similar tools.

  class CallTreePrinter  < AbstractPrinter
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)
        
      # add a header - this information is somewhat arbitrary
      @output << "events: "
      case RubyProf.measure_mode
        when RubyProf::PROCESS_TIME
          @value_scale = RubyProf::CLOCKS_PER_SEC;
          @output << 'process_time'
        when RubyProf::WALL_TIME
          @value_scale = 1_000_000
          @output << 'wall_time'
        when RubyProf.const_defined?(:CPU_TIME) && RubyProf::CPU_TIME
          @value_scale = RubyProf.cpu_frequency
          @output << 'cpu_time'
        when RubyProf.const_defined?(:ALLOCATIONS) && RubyProf::ALLOCATIONS
          @value_scale = 1
          @output << 'allocations'
        when RubyProf.const_defined?(:MEMORY) && RubyProf::MEMORY
          @value_scale = 1
          @output << 'memory'
        when RubyProf.const_defined?(:GC_RUNS) && RubyProf::GC_RUNS
          @value_scale = 1
          @output << 'gc_runs'
        when RubyProf.const_defined?(:GC_TIME) && RubyProf::GC_TIME
          @value_scale = 1000000
          @output << 'gc_time'
        else
          raise "Unknown measure mode: #{RubyProf.measure_mode}"
      end
      @output << "\n\n"

      print_threads
    end

    def print_threads
      @result.threads.each do |thread_id, methods|
        print_methods(thread_id, methods)
      end
    end

    def convert(value)
      (value * @value_scale).round
    end

    def file(method)
      File.expand_path(method.source_file)
    end

    def name(method)
      "#{method.klass_name}::#{method.method_name}"
    end

    def print_methods(thread_id, methods)
      methods.reverse_each do |method| 
        # Print out the file and method name
        @output << "fl=#{file(method)}\n"
        @output << "fn=#{name(method)}\n"

        # Now print out the function line number and its self time
        @output << "#{method.line} #{convert(method.self_time)}\n"

        # Now print out all the children methods
        method.children.each do |callee|
          @output << "cfl=#{file(callee.target)}\n"
          @output << "cfn=#{name(callee.target)}\n"
          @output << "calls=#{callee.called} #{callee.line}\n"

          # Print out total times here!
          @output << "#{callee.line} #{convert(callee.total_time)}\n"
        end
      @output << "\n"
      end
    end #end print_methods
  end # end class
end # end packages
