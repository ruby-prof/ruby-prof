# encoding: utf-8

module RubyProf
  class AbstractPrinter
    def initialize(result, options = {})
      @result = result
      @output = nil
      @options = options
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
    def setup_options(options = {})
      @options = options
    end

    def min_percent
      @options[:min_percent] || 0
    end

    def print_file
      @options[:print_file] || false
    end

    def sort_method
      @options[:sort_method] || :total_time
    end

    def method_name(method)
      name = method.full_name
      if print_file
        name += " (#{method.source_file}:#{method.line}}"
      end
      name
    end
  end
end
