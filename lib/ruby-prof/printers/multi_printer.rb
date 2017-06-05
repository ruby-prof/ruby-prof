# encoding: utf-8

module RubyProf
  # Helper class to simplify printing profiles of several types from
  # one profiling run. Currently prints a flat profile, a callgrind
  # profile, a call stack profile and a graph profile.
  class MultiPrinter
    def initialize(result, printers = [:stack, :graph, :tree, :flat])
      @stack_printer = CallStackPrinter.new(result) if printers.include?(:stack)
      @graph_printer = GraphHtmlPrinter.new(result) if printers.include?(:graph)
      @tree_printer = CallTreePrinter.new(result) if printers.include?(:tree)
      @flat_printer = FlatPrinter.new(result) if printers.include?(:flat)
    end

    def self.needs_dir?
      true
    end

    # create profile files under options[:path] or the current
    # directory. options[:profile] is used as the base name for the
    # pofile file, defaults to "profile".
    def print(options)
      validate_print_params(options)

      @profile = options.delete(:profile) || "profile"
      @directory = options.delete(:path) || File.expand_path(".")

      print_to_stack(options) if @stack_printer
      print_to_graph(options) if @graph_printer
      print_to_tree(options) if @tree_printer
      print_to_flat(options) if @flat_printer
    end

    # the name of the call stack profile file
    def stack_profile
      "#{@directory}/#{@profile}.stack.html"
    end

    # the name of the graph profile file
    def graph_profile
      "#{@directory}/#{@profile}.graph.html"
    end

    # the name of the callgrind profile file
    def tree_profile
      "#{@directory}/#{@profile}.callgrind.out.#{$$}"
    end

    # the name of the flat profile file
    def flat_profile
      "#{@directory}/#{@profile}.flat.txt"
    end

    def print_to_stack(options)
      File.open(stack_profile, "w") do |f|
        @stack_printer.print(f, options.merge(:graph => "#{@profile}.graph.html"))
      end
    end

    def print_to_graph(options)
      File.open(graph_profile, "w") do |f|
        @graph_printer.print(f, options)
      end
    end

    def print_to_tree(options)
      @tree_printer.print(options.merge(:path => @directory, :profile => @profile))
    end

    def print_to_flat(options)
      File.open(flat_profile, "w") do |f|
        @flat_printer.print(f, options)
      end
    end

    def validate_print_params(options)
      if options.is_a?(IO)
        raise ArgumentError, "#{self.class.name}#print cannot print to IO objects"
      elsif !options.is_a?(Hash)
        raise ArgumentError, "#{self.class.name}#print requires an options hash"
      end
    end
  end
end
