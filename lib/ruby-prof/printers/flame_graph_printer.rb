# encoding: utf-8

require 'erb'
require 'json'

module RubyProf
  # Prints a HTML flame graph visualization of the call tree.
  #
  # To use the printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::FlameGraphPrinter.new(result)
  #   printer.print(STDOUT)

  class FlameGraphPrinter < AbstractPrinter
    include ERB::Util

    # Specify print options.
    #
    # output - Any IO object, including STDOUT or a file.
    #
    # Keyword arguments:
    #   title:       - a String to override the default "ruby-prof flame graph"
    #                  title of the report.
    #
    # Also accepts min_percent:, max_percent:, filter_by:, and sort_method:
    # from AbstractPrinter.
    def print(output = STDOUT, title: "ruby-prof flame graph",
              min_percent: 0, max_percent: 100, filter_by: :self_time, sort_method: nil, max_depth: nil, **)
      @min_percent = min_percent
      @max_percent = max_percent
      @filter_by = filter_by
      @sort_method = sort_method
      @max_depth = max_depth
      @title = title
      output << ERB.new(self.template).result(binding)
    end

    attr_reader :title

    def build_flame_data(call_tree, depth = 0)
      node = {
        name: call_tree.target.full_name,
        value: call_tree.total_time,
        self_value: call_tree.self_time,
        called: call_tree.called,
        children: []
      }

      if @max_depth.nil? || depth < @max_depth
        call_tree.children.each do |child|
          node[:children] << build_flame_data(child, depth + 1)
        end
      end

      node
    end

    def flame_data_json
      threads = @result.threads.map do |thread|
        {
          id: thread.id,
          fiber_id: thread.fiber_id,
          total_time: thread.total_time,
          data: build_flame_data(thread.call_tree)
        }
      end
      JSON.generate(threads)
    end

    def template
      open_asset('flame_graph_printer.html.erb')
    end
  end
end
