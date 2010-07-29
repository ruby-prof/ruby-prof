require 'set'
require 'ruby-prof/abstract_printer'

module RubyProf
  # Generates graphviz graph in dot format.
  # To use the dot printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::DotPrinter.new(result)
  #   printer.print(STDOUT)
  # 
  # You can use either dot viewer such as GraphViz, or the dot command line tool
  # to reformat the output into a wide variety of outputs:
  # 
  #   dot -Tpng graph.dot > graph.png
  # 
  class DotPrinter < RubyProf::AbstractPrinter  
    CLASS_COLOR = '"#666666"'
    # Creates the DotPrinter using a RubyProf::Result.
    def initialize(result)
      super(result)
      @seen_methods = Set.new
    end
        
    # Print a graph report to the provided output.
    #  
    # output - Any IO oject, including STDOUT or a file. The default value is
    # STDOUT.
    #  
    # options - Hash of print options.  See #setup_options 
    #           for more information.
    #
    # When profiling results that cover a large number of method calls it
    # helps to use the :min_percent option, for example:
    #  
    #   DotPrinter.new(result).print(STDOUT, :min_percent=>5)
    # 
    def print(output = STDOUT, options = {})
      @output = output
      setup_options(options)
      mode = RubyProf.constants.find{|c| RubyProf.const_get(c) == RubyProf.measure_mode}
      total_time = thread_times.values.inject{|a,b| a+b}
      
      puts 'digraph "Profile" {'
      puts "label=\"#{mode} >=#{min_percent}%\\nTotal: #{total_time}\""
      print_threads
      puts '}'
    end

    private 
    
    # Computes the total time per thread:
    def thread_times
      @thread_times ||= begin
        times = {}
        @result.threads.each do |thread_id, methods|
          toplevel = methods.sort.last

          total_time = toplevel.total_time
          # This looks like a hack for very small times... from GraphPrinter
          total_time = 0.01 if total_time == 0 
          times[thread_id] = total_time
        end
        
        times
      end
    end
    
    def print_threads
      # sort assumes that spawned threads have higher object_ids
      @result.threads.sort.each do |thread_id, methods|
        puts "subgraph \"Thread #{thread_id}\" {"
        
        print_methods(thread_id, methods)
        puts "}"
        
        print_classes(thread_id, methods)
      end
    end
    
    # Determines an ID to use to represent the subject in the Dot file.
    def dot_id(subject)
      subject.object_id
    end
    
    def print_methods(thread_id, methods)
      total_time = thread_times[thread_id]
      # Print each method in total time order
      methods.reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100
        self_percentage = (method.self_time/total_time) * 100
        
        next if total_percentage < min_percent
        name = method_name(method).split("#").last
        puts "#{dot_id(method)} [label=\"#{name}\\n(#{total_percentage.round}%)\"];"
        @seen_methods << method
        print_children(total_time, method)
      end
    end
      
    def print_classes(thread_id, methods)
      methods.group_by{|m| m.klass_name}.each do |cls, methods|
        # Filter down to just seen methods
        big_methods, small_methods  = methods.partition{|m| @seen_methods.include? m}
        
        if !big_methods.empty?
          puts "subgraph cluster_#{cls.object_id} {"
          puts "label = \"#{cls}\";"
          puts "fontcolor = #{CLASS_COLOR};"
          puts "color = #{CLASS_COLOR};"
          big_methods.each do |m|
            puts "#{m.object_id};"
          end
          puts "}"  
        end        
      end
    end
    
    def print_children(total_time, method)
      method.aggregate_children.sort_by(&:total_time).reverse.each do |child|
        
        target_percentage = (child.target.total_time / total_time) * 100.0
        next if target_percentage < min_percent
        
        # Get children method
        puts "#{dot_id(method)} -> #{dot_id(child.target)} [label=\"#{child.called}/#{child.target.called}\"];"
      end
    end
    
    # Silly little helper for printing to the @output
    def puts(str)
      @output.puts(str)
    end
    
  end
end