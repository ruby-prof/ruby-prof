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
  class DotPrinter < RubyProf::AbstractPrinter  
    # Creates the DotPrinter using a RubyProf::Result.
    def initialize(result)
      super(result)
      @thread_times = {}
      @seen_methods = Set.new
      compute_times
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
      total_time = @thread_times.values.inject{|a,b| a+b}
      
      @output.puts 'digraph "Profile" {'
      @output.puts "label=\"#{mode} >=#{min_percent}%\\nTotal: #{total_time}\""
      print_threads
      @output.puts '}'
    end

    private 
    
    def compute_times
      # Sort methods from longest to shortest total time
      @result.threads.each do |thread_id, methods|
        methods = methods.sort
      
        toplevel = methods.last
        total_time = toplevel.total_time
        total_time = 0.01 if total_time == 0
        @thread_times[thread_id] = total_time
      end
    end
    
    def print_threads
      # sort assumes that spawned threads have higher object_ids
      @result.threads.sort.each do |thread_id, methods|
        @output.puts "subgraph \"Thread #{thread_id}\" {"
        
        print_methods(thread_id, methods)
        @output.puts "}"
        
        print_classes(thread_id, methods)
      end
    end
    
    def dot_id(method)
      method.object_id
    end
    
    def print_methods(thread_id, methods)
      total_time = @thread_times[thread_id]
      # Print each method in total time order
      methods.reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100
        self_percentage = (method.self_time/total_time) * 100
        
        next if total_percentage < min_percent
        name = method_name(method).split("#").last
        @output.puts "#{dot_id(method)} [label=\"#{name}\\n(#{total_percentage.round}%)\"];"
        @seen_methods << method
        print_children(total_time, method)
      end
    end
      
    def print_classes(thread_id, methods)
      methods.group_by{|m| m.klass_name}.each do |cls, methods|
        # Filter down to just seen methods
        big_methods, small_methods  = methods.partition{|m| @seen_methods.include? m}
        
        if !big_methods.empty?
          @output.puts "subgraph cluster_#{cls.object_id} {"
          @output.puts "label = \"#{cls}\";"
          @output.puts "fontcolor = \"#666666\";"
          @output.puts "color = \"#666666\";"
          big_methods.each do |m|
            @output.puts "#{m.object_id};"
          end
          @output.puts "}"  
        end
        
        #small_methods.each do |m|
        #  @output.puts "#{m.object_id} [label=\" \" shape=point];"
        #end
        
      end
    end
    
    def print_children(total_time, method)
      method.aggregate_children.sort_by(&:total_time).reverse.each do |child|
        
        target_percentage = (child.target.total_time / total_time) * 100.0
        next if target_percentage < min_percent
        
        # Get children method
        @output.puts "#{dot_id(method)} -> #{dot_id(child.target)} [label=\"#{child.called}/#{child.target.called}\"];"
        
        # @output << sprintf("%#{TIME_WIDTH}.2f", child.total_time)
        # @output << sprintf("%#{TIME_WIDTH}.2f", child.self_time)
        # @output << sprintf("%#{TIME_WIDTH}.2f", child.wait_time)
        # @output << sprintf("%#{TIME_WIDTH}.2f", child.children_time)
        # 
        # call_called = "#{child.called}/#{child.target.called}"
        # @output << sprintf("%#{CALL_WIDTH}s", call_called)
        # @output << sprintf("     %s", child.target.full_name)
        # @output << "\n"
      end
    end
  end
end 

if __FILE__ == $0
  require File.dirname(__FILE__) + '/../ruby-prof.rb'
  puts "Running sample:"
  class DogHouse
    def initialize(count)
      @count = count
      @dogs = []
      add_dogs(count)
    end
    
    def add_dogs(count)
      count.times do 
        @dogs << Dog.new
      end
    end
    
    def feed
      @dogs.each{|d| d.feed }
    end
    
    def let_out
      @dogs.each{|d| @dogs.delete(d); d.play }
    end
  end
  
  class Dog
    def feed
      puts "Woof munch munch"
    end
    
    def play
      puts "Woof Waggle"
      sleep 0.01 # hard work!
    end
  end
  
  RubyProf.start
  5.times do |i|
    dh = DogHouse.new(i)
    dh.feed
    dh.let_out
  end
  result = RubyProf.stop

  open("example.dot","w") do |io|
    RubyProf::DotPrinter.new(result).print(io)
  end
end