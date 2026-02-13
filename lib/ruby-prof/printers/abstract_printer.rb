# encoding: utf-8

module RubyProf
  # This is the base class for all Printers. It is never used directly.
  class AbstractPrinter
    # :stopdoc:
    def self.needs_dir?
      false
    end
    # :startdoc:

    # Create a new printer.
    #
    # result should be the output generated from a profiling run
    def initialize(result)
      @result = result
      @output = nil
    end

    attr_reader :min_percent, :max_percent, :filter_by, :sort_method

    # Returns the time format used to show when a profile was run
    def time_format
      '%A, %B %-d at %l:%M:%S %p (%Z)'
    end

    # Prints a report to the provided output.
    #
    # output - Any IO object, including STDOUT or a file.
    # The default value is STDOUT.
    #
    # Keyword arguments:
    #   min_percent  - Number 0 to 100 that specifies the minimum
    #                  %self (the methods self time divided by the
    #                  overall total time) that a method must take
    #                  for it to be printed out in the report.
    #                  Default value is 0.
    #
    #   max_percent  - Number 0 to 100 that specifies the maximum
    #                  %self for methods to include.
    #                  Default value is 100.
    #
    #   filter_by    - Which time metric to use when applying
    #                  min_percent and max_percent filters.
    #                  Default value is :self_time.
    #
    #   sort_method  - Specifies method used for sorting method infos.
    #                  Available values are :total_time, :self_time,
    #                  :wait_time, :children_time.
    #                  Default value depends on the printer.
    def print(output = STDOUT, min_percent: 0, max_percent: 100, filter_by: :self_time, sort_method: nil, **)
      @output = output
      @min_percent = min_percent
      @max_percent = max_percent
      @filter_by = filter_by
      @sort_method = sort_method
      print_threads
    end

    def method_location(method)
      if method.source_file
        "#{method.source_file}:#{method.line}"
      end
    end

    def method_href(thread, method)
      h(method.full_name.gsub(/[><#\.\?=:]/,"_") + "_" + thread.fiber_id.to_s)
    end

    def open_asset(file)
      path = File.join(File.expand_path('../../assets', __FILE__), file)
      File.open(path, 'rb').read
    end

    def print_threads
      @result.threads.each do |thread|
        print_thread(thread)
      end
    end

    def print_thread(thread)
      print_header(thread)
      print_methods(thread)
      print_footer(thread)
    end

    def print_header(thread)
      @output << "Measure Mode: %s\n" % @result.measure_mode_string
      @output << "Thread ID: %d\n" % thread.id
      @output << "Fiber ID: %d\n" % thread.fiber_id unless thread.id == thread.fiber_id
      @output << "Total: %0.6f\n" % thread.total_time
      @output << "Sort by: #{sort_method}\n"
      @output << "\n"
      print_column_headers
    end

    def print_column_headers
    end

    def print_footer(thread)
      metric_data = {
        0 => { label: "time", prefix: "", suffix: "spent" },
        1 => { label: "time", prefix: "", suffix: "spent" },
        2 => { label: "allocations", prefix: "number of ", suffix: "made" },
        3 => { label: "memory", prefix: "", suffix: "used" }
      }

      metric = metric_data[@result.measure_mode]

      metric_label = metric[:label]
      metric_suffix = metric[:suffix]
      metric_prefix = metric[:prefix]

      metric1 = "#{metric_label} #{metric_suffix}"
      metric2 = "#{metric_prefix}#{metric1}"
      metric3 = metric_label

      # Output the formatted text
      @output << <<~EOT

        * recursively called methods

        Columns are:

          %self     - The percentage of #{metric1} by this method relative to the total #{metric3} in the entire program.
          total     - The total #{metric2} by this method and its children.
          self      - The #{metric2} by this method.
          wait      - The time this method spent waiting for other threads.
          child     - The #{metric2} by this method's children.
          calls     - The number of times this method was called.
          name      - The name of the method.
          location  - The location of the method.

        The interpretation of method names is:

          * MyObject#test - An instance method "test" of the class "MyObject"
          * <Object:MyObject>#test - The <> characters indicate a method on a singleton class.

      EOT
    end
  end
end
