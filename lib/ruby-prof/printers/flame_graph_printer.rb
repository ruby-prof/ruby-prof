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
    # options - Hash table
    #   :title       - a String to override the default "ruby-prof flame graph"
    #                  title of the report.
    #
    #   :min_percent - Number 0 to 100 that specifies the minimum
    #                  %total time that a method must take for it to
    #                  be included in the flame graph.
    #                  Default value is 0.
    def print(output = STDOUT, options = {})
      setup_options(options)
      output << @erb.result(binding)
    end

    # :enddoc:
    def setup_options(options)
      super(options)
      @erb = ERB.new(self.template)
    end

    def title
      @title ||= @options.delete(:title) || "ruby-prof flame graph"
    end

    def build_flame_data(call_tree, visited = Set.new)
      node = {
        name: call_tree.target.full_name,
        value: call_tree.total_time,
        self_value: call_tree.self_time,
        called: call_tree.called,
        children: []
      }

      unless visited.include?(call_tree.target)
        visited.add(call_tree.target)
        call_tree.children.sort_by { |c| -c.total_time }.each do |child|
          node[:children] << build_flame_data(child, visited)
        end
        visited.delete(call_tree.target)
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
