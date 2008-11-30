module RubyProf
  class AbstractPrinter
    def initialize(result)
      @result = result
      @output = nil
      @options = {}
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
    def setup_options(options = {})
      @options = options
    end      

    def min_percent
      @options[:min_percent] || 0
    end
    
    def print_file
      @options[:print_file] || false
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