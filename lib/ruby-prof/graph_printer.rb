require 'ruby-prof/abstract_printer'

module RubyProf
  # Generates graph[link:files/examples/graph_txt.html] profile reports as text. 
  # To use the graph printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::GraphPrinter.new(result, 5)
  #   printer.print(STDOUT, 0)
  #
  # The constructor takes two arguments.  The first is
  # a RubyProf::Result object generated from a profiling
  # run.  The second is the minimum %total (the methods 
  # total time divided by the overall total time) that
  # a method must take for it to be printed out in 
  # the report.  Use this parameter to eliminate methods
  # that are not important to the overall profiling results.

  class GraphPrinter < AbstractPrinter
    PERCENTAGE_WIDTH = 8
    TIME_WIDTH = 10
    CALL_WIDTH = 17
  
    # Create a GraphPrinter.  Result is a RubyProf::Result  
    # object generated from a profiling run.
    def initialize(result)
      super(result)
      @thread_times = Hash.new
      calculate_thread_times
    end

    def calculate_thread_times
      # Cache thread times since this is an expensive
      # operation with the required sorting      
      @result.threads.each do |thread_id, methods|
        top = methods.sort.last
        
        thread_time = 0.01
        thread_time = top.total_time if top.total_time > 0

        @thread_times[thread_id] = thread_time 
      end
    end
    
    # Print a graph report to the provided output.
    # 
    # output - Any IO oject, including STDOUT or a file. 
    # The default value is STDOUT.
    # 
    # options - Hash of print options.  See #setup_options 
    #           for more information.
    #
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)
      print_threads
    end

    private 
    def print_threads
      # sort assumes that spawned threads have higher object_ids
      @result.threads.sort.each do |thread_id, methods|
        print_methods(thread_id, methods)
        @output << "\n" * 2
      end
    end
    
    def print_methods(thread_id, methods)
      # Sort methods from longest to shortest total time
      methods = methods.sort
      
      toplevel = methods.last
      total_time = toplevel.total_time
      if total_time == 0
        total_time = 0.01
      end
      
      print_heading(thread_id)
    
      # Print each method in total time order
      methods.reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100
        self_percentage = (method.self_time/total_time) * 100
        
        next if total_percentage < min_percent
        
        @output << "-" * 80 << "\n"

        print_parents(thread_id, method)
    
        # 1 is for % sign
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f\%", total_percentage)
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f\%", self_percentage)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.children_time)
        @output << sprintf("%#{CALL_WIDTH}i", method.called)
        @output << sprintf("     %s", method_name(method))
        if print_file
          @output << sprintf("  %s:%s", method.source_file, method.line)
        end          
        @output << "\n"
    
        print_children(method)
      end
    end
  
    def print_heading(thread_id)
      @output << "Thread ID: #{thread_id}\n"
      @output << "Total Time: #{@thread_times[thread_id]}\n"
      @output << "\n"
      
      # 1 is for % sign
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%total")
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%self")
      @output << sprintf("%#{TIME_WIDTH}s", "total")
      @output << sprintf("%#{TIME_WIDTH}s", "self")
      @output << sprintf("%#{TIME_WIDTH}s", "wait")
      @output << sprintf("%#{TIME_WIDTH}s", "child")
      @output << sprintf("%#{CALL_WIDTH}s", "calls")
      @output << "   Name"
      @output << "\n"
    end
    
    def print_parents(thread_id, method)
      method.aggregate_parents.each do |caller|
        next unless caller.parent
        @output << " " * 2 * PERCENTAGE_WIDTH
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.children_time)
    
        call_called = "#{caller.called}/#{method.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("     %s", caller.parent.target.full_name)
        @output << "\n"
      end
    end
  
    def print_children(method)
      method.aggregate_children.each do |child|
        # Get children method
        
        @output << " " * 2 * PERCENTAGE_WIDTH
        
        @output << sprintf("%#{TIME_WIDTH}.2f", child.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.children_time)

        call_called = "#{child.called}/#{child.target.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("     %s", child.target.full_name)
        @output << "\n"
      end
    end
  end
end 

