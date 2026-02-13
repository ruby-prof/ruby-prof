# encoding: utf-8

module RubyProf
  # Helper class to simplify printing profiles of several types from
  # one profiling run. Currently prints a flat profile, a callgrind
  # profile, a call stack profile and a graph profile.
  class MultiPrinter
    def initialize(result, printers = [:flat, :graph, :graph_html, :flame_graph, :stack])
      @flat_printer = printers.include?(:flat) ? FlatPrinter.new(result) : nil

      @graph_printer = printers.include?(:graph) ? GraphPrinter.new(result) : nil
      @graph_html_printer = printers.include?(:graph_html) ? GraphHtmlPrinter.new(result) : nil

      @tree_printer = printers.include?(:tree) ? CallTreePrinter.new(result) : nil
      @call_info_printer = printers.include?(:call_tree) ? CallInfoPrinter.new(result) : nil

      @stack_printer = printers.include?(:stack) ? CallStackPrinter.new(result) : nil
      @flame_graph_printer = printers.include?(:flame_graph) ? FlameGraphPrinter.new(result) : nil
      @dot_printer = printers.include?(:dot) ? DotPrinter.new(result) : nil
    end

    def self.needs_dir?
      true
    end

    # Create profile files under the specified directory.
    #
    # Keyword arguments:
    #   profile: - Base name for profile files. Default is "profile".
    #   path:    - Directory to write files to. Default is current directory.
    #
    # Also accepts min_percent:, sort_method:, and other printer-specific kwargs.
    def print(profile: "profile", path: File.expand_path("."), **options)
      @file_name = profile
      @directory = path

      print_to_flat(**options) if @flat_printer

      print_to_graph(**options) if @graph_printer
      print_to_graph_html(**options) if @graph_html_printer

      print_to_stack(**options) if @stack_printer
      print_to_flame_graph(**options) if @flame_graph_printer
      print_to_call_info(**options) if @call_info_printer
      print_to_tree(**options) if @tree_printer
      print_to_dot(**options) if @dot_printer
    end

    # the name of the flat profile file
    def flat_report
      "#{@directory}/#{@file_name}.flat.txt"
    end

    # the name of the graph profile file
    def graph_report
      "#{@directory}/#{@file_name}.graph.txt"
    end

    def graph_html_report
      "#{@directory}/#{@file_name}.graph.html"
    end

    # the name of the callinfo profile file
    def call_info_report
      "#{@directory}/#{@file_name}.call_tree.txt"
    end

    # the name of the callgrind profile file
    def tree_report
      "#{@directory}/#{@file_name}.callgrind.out.#{$$}"
    end

    # the name of the call stack profile file
    def stack_report
      "#{@directory}/#{@file_name}.stack.html"
    end

    # the name of the flame graph profile file
    def flame_graph_report
      "#{@directory}/#{@file_name}.flame_graph.html"
    end

    # the name of the call stack profile file
    def dot_report
      "#{@directory}/#{@file_name}.dot"
    end

    def print_to_flat(**options)
      File.open(flat_report, "wb") do |file|
        @flat_printer.print(file, **options)
      end
    end

    def print_to_graph(**options)
      File.open(graph_report, "wb") do |file|
        @graph_printer.print(file, **options)
      end
    end

    def print_to_graph_html(**options)
      File.open(graph_html_report, "wb") do |file|
        @graph_html_printer.print(file, **options)
      end
    end

    def print_to_call_info(**options)
      File.open(call_info_report, "wb") do |file|
        @call_info_printer.print(file, **options)
      end
    end

    def print_to_tree(**options)
      @tree_printer.print(path: @directory, **options)
    end

    def print_to_stack(**options)
      File.open(stack_report, "wb") do |file|
        @stack_printer.print(file, **options)
      end
    end

    def print_to_flame_graph(**options)
      File.open(flame_graph_report, "wb") do |file|
        @flame_graph_printer.print(file, **options)
      end
    end

    def print_to_dot(**options)
      File.open(dot_report, "wb") do |file|
        @dot_printer.print(file, **options)
      end
    end
  end
end
