# encoding: utf-8

require 'fiber'
require 'thread'
require 'fileutils'

module RubyProf
  # Generate profiling information in callgrind format for use by
  # kcachegrind and similar tools.
  #
  # Note: when profiling for a callgrind printer, one should use the
  # merge_fibers: true option when creating the profile. Otherwise
  # each fiber would appear as a separate profile.

  class CallTreePrinter < AbstractPrinter

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

    def print(options = {})
      setup_options(options)
      determine_event_specification_and_value_scale
      print_threads
    end

    def print_threads
      remove_subsidiary_files_from_previous_profile_runs
      # TODO: merge fibers of a given thread here, instead of relying
      # on the profiler to merge fibers.
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
      File.open(file_path_for_thread(thread), "w") do |f|
        print_headers(f, thread)
        thread.methods.reverse_each do |method|
          print_method(f, method)
        end
      end
    end

    def path
      @options[:path] || "."
    end

    def base_name
      @options[:profile] || "profile"
    end

    def remove_subsidiary_files_from_previous_profile_runs
      pattern = [base_name, "callgrind.out", $$, "*"].join(".")
      files = Dir.glob(File.join(path, pattern))
      FileUtils.rm_f(files)
    end

    def file_name_for_thread(thread)
      if thread.fiber_id == Fiber.current.object_id
        [base_name, "callgrind.out", $$].join(".")
      else
        [base_name, "callgrind.out", $$, thread.fiber_id].join(".")
      end
    end

    def file_path_for_thread(thread)
      File.join(path, file_name_for_thread(thread))
    end

    def print_headers(output, thread)
      output << "#{@event_specification}\n\n"
      # this doesn't work. kcachegrind does not fully support the spec.
      # output << "thread: #{thread.id}\n\n"
    end

    def print_method(output, method)
      # Print out the file and method name
      output << "fl=#{file(method)}\n"
      output << "fn=#{method_name(method)}\n"

      # Now print out the function line number and its self time
      output << "#{method.line} #{convert(method.self_time)}\n"

      # Now print out all the children methods
      method.children.each do |callee|
        output << "cfl=#{file(callee.target)}\n"
        output << "cfn=#{method_name(callee.target)}\n"
        output << "calls=#{callee.called} #{callee.line}\n"

        # Print out total times here!
        output << "#{callee.line} #{convert(callee.total_time)}\n"
      end
      output << "\n"
    end
  end
end
