# encoding: utf-8

require 'set'

module RubyProf
  # Generates a graphviz graph in dot format.
  #
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
    CLUSTER_COLORS = %w[#1A35A6 #2E86C1 #1ABC9C #5B2C8E #2471A3 #148F77 #1F618D #7D3C98]

    # Creates the DotPrinter using a RubyProf::Proile.
    def initialize(result)
      super(result)
      @seen_methods = Set.new
      @class_color_map = {}
      @color_index = 0
    end

    # Print a graph report to the provided output.
    #
    # output - Any IO object, including STDOUT or a file. The default value is
    # STDOUT.
    #
    # Keyword arguments - See AbstractPrinter#print for available options.
    #
    # When profiling results that cover a large number of method calls it
    # helps to use the min_percent: option, for example:
    #
    #   DotPrinter.new(result).print(STDOUT, min_percent: 5)
    #
    def print(output = STDOUT, min_percent: 0, max_percent: 100, filter_by: :self_time, sort_method: nil, **)
      @output = output
      @min_percent = min_percent
      @max_percent = max_percent
      @filter_by = filter_by
      @sort_method = sort_method

      puts 'digraph "Profile" {'
      puts 'rankdir=TB;'
      puts 'bgcolor="#FAFAFA";'
      puts 'node [fontname="Helvetica" fontsize=11 style="filled,rounded" shape=box fillcolor="#FFFFFF" color="#CCCCCC" penwidth=1.2];'
      puts 'edge [fontname="Helvetica" fontsize=9 color="#5B7DB1" arrowsize=0.7];'
      puts 'labelloc=t;'
      puts 'labeljust=l;'
      print_threads
      puts '}'
    end

    private

    # Something of a hack, figure out which constant went with the
    # RubyProf.measure_mode so that we can display it.  Otherwise it's easy to
    # forget what measurement was made.
    def mode_name
      RubyProf.constants.find{|c| RubyProf.const_get(c) == RubyProf.measure_mode}
    end

    def print_threads
      @result.threads.each do |thread|
        puts "subgraph \"Thread #{thread.id}\" {"

        print_thread(thread)
        puts "}"

        print_classes(thread)
      end
    end

    # Determines an ID to use to represent the subject in the Dot file.
    def dot_id(subject)
      subject.object_id
    end

    def color_for_class(klass_name)
      @class_color_map[klass_name] ||= begin
        color = CLUSTER_COLORS[@color_index % CLUSTER_COLORS.length]
        @color_index += 1
        color
      end
    end

    def node_color(total_percentage)
      if total_percentage >= 50
        '#0D2483'
      elsif total_percentage >= 25
        '#1A35A6'
      elsif total_percentage >= 10
        '#2E86C1'
      elsif total_percentage >= 5
        '#D4E6F1'
      else
        '#FFFFFF'
      end
    end

    def node_fontcolor(total_percentage)
      total_percentage >= 10 ? '#FFFFFF' : '#333333'
    end

    def print_thread(thread)
      total_time = thread.total_time
      thread.methods.sort_by(&sort_method).reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100

        next if total_percentage < min_percent
        name = method.full_name.split("#").last
        label = "#{name}\\n(#{total_percentage.round}%)"

        # Only emit fill/font attrs when they differ from the default (white/#333)
        fill = node_color(total_percentage)
        fontcolor = node_fontcolor(total_percentage)
        attrs = "label=\"#{label}\""
        attrs += " fillcolor=\"#{fill}\" fontcolor=\"#{fontcolor}\"" unless fill == '#FFFFFF'

        puts "#{dot_id(method)} [#{attrs}];"
        @seen_methods << method
        print_edges(total_time, method)
      end
    end

    def print_classes(thread)
      grouped = {}
      thread.methods.each{|m| grouped[m.klass_name] ||= []; grouped[m.klass_name] << m}
      grouped.each do |cls, methods2|
        # Filter down to just seen methods
        big_methods = methods2.select{|m| @seen_methods.include? m}

        if !big_methods.empty?
          color = color_for_class(cls)
          puts "subgraph cluster_#{cls.object_id} {"
          puts "label = \"#{cls}\";"
          puts "fontname = \"Helvetica\";"
          puts "fontcolor = \"#{color}\";"
          puts "fontsize = 14;"
          puts "color = \"#{color}\";"
          puts "style = \"rounded,dashed\";"
          puts "penwidth = 1.5;"
          big_methods.each do |m|
            puts "#{m.object_id};"
          end
          puts "}"
        end
      end
    end

    def print_edges(total_time, method)
      method.call_trees.callees.sort_by(&:total_time).reverse.each do |call_tree|
        target_percentage = (call_tree.target.total_time / total_time) * 100.0
        next if target_percentage < min_percent
        next unless @seen_methods.include?(call_tree.target)

        edge_width = [0.5 + (target_percentage / 20.0), 4.0].min
        puts "#{dot_id(method)} -> #{dot_id(call_tree.target)} [label=\"#{call_tree.called}/#{call_tree.target.called}\" penwidth=#{format('%.1f', edge_width)}];"
      end
    end

    # Silly little helper for printing to the @output
    def puts(str)
      @output.puts(str)
    end

  end
end
