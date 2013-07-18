# encoding: utf-8

module RubyProf
  # Prints a CSV report of all methods that were called together with
  # the file location. The column headers come from the yourkit profiler
  # to make the results easier comparable.

  
  class PlatformsCSVPrinter < AbstractPrinter
    # Override for this printer to sort by self time by default
    def sort_method
      @options[:sort_method] || :self_time
    end

	private

    def print_header(thread)
      @output << "Name, File location, Time (ms),Avg. Time (ms),Own Time (ms),Invocation Count, Min. Level\n"
    end

    def print_methods(thread)
	  total_time = thread.total_time
      
      methods = thread.methods
      sum = 0
      methods.each do |method|
        self_percent = (method.self_time / total_time) * 100
        next if self_percent < min_percent

        sum += method.self_time
        
          @output << "%s, %s, %.0f, %.0f, %.0f, %d, %d\n" % [
                      method.full_name.to_s,
                      method.source_file.to_s,                  
                      method.total_time * 1000,                   
                      method.total_time / Float(method.called) * 1000,
                      method.self_time * 1000,                    
                      method.called,                       
                      method.min_depth + 1,   # + 1 because Java profilers start from 1
                      
                  ]
      end
    end

    def print_footer(thread)
      
    end
  end
end
