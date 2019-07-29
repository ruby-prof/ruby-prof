# encoding: utf-8

module RubyProf
  class AbstractPrinter
    # Create a new printer.
    #
    # result should be the output generated from a profiling run
    def initialize(result)
      @result = result
      @output = nil
    end

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
    #   :sort_method - Specifies method used for sorting method infos.
    #                  Available values are :total_time, :self_time,
    #                  :wait_time, :children_time
    #                  Default value is :total_time
    #    :editor_uri - Specifies editor uri scheme used for opening files
    #                  e.g. :atm or :mvim. For OS X default is :txmt.
    #                  Pass false to print bare filenames.
    #                  Use RUBY_PROF_EDITOR_URI environment variable to override.
    def setup_options(options = {})
      @options = options
    end

    def min_percent
      @options[:min_percent] || 0
    end

    def print_file
      @options[:print_file] || false
    end

    def time_format
      '%A, %B %-d at %l:%M:%S %p (%Z)'
    end

    def sort_method
      @options[:sort_method]
    end

    def editor_uri
      if ENV.key?('RUBY_PROF_EDITOR_URI')
        ENV['RUBY_PROF_EDITOR_URI'] || false
      elsif @options.key?(:editor_uri)
        @options[:editor_uri]
      else
        RUBY_PLATFORM =~ /darwin/ ? 'txmt' : false
      end
    end

    def method_name(method)
      name = method.full_name
      if print_file
        name += " (#{method.source_file}:#{method.line}}"
      end
      name
    end

    # Print a profiling report to the provided output.
    #
    # output - Any IO object, including STDOUT or a file.
    # The default value is STDOUT.
    #
    # options - Hash of print options.  See #setup_options
    # for more information.  Note that each printer can
    # define its own set of options.
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)
      print_threads
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
      @output << "Measure Mode: %s\n" % RubyProf.measure_mode_string
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
      @output << <<~EOT
      
        * recursively called methods

        Columns are:

          %self - The percentage of time spent in this method, derived from self_time/total_time
          total - The time spent in this method and its children.
          self  - The time spent in this method.
          wait  - amount of time this method waited for other threads
          child - The time spent in this method's children.
          calls - The number of times this method was called.
          name  - The name of the method.

        The interpretation of method names is:

          * MyObject#test - An instance method "test" of the class "MyObject"
          * <Object:MyObject>#test - The <> characters indicate a method on a singleton class.
      EOT
    end

    # whether this printer need a :path option pointing to a directory
    def self.needs_dir?
      false
    end
  end
end
