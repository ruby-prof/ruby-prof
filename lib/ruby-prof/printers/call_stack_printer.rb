# encoding: utf-8

require 'erb'
require 'fileutils'
require 'base64'
require 'set'
require 'stringio'

module RubyProf
  # Prints a HTML visualization of the call tree.
  #
  # To use the printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::CallStackPrinter.new(result)
  #   printer.print(STDOUT)

  class CallStackPrinter < AbstractPrinter
    include ERB::Util

    # Specify print options.
    #
    # output     - Any IO object, including STDOUT or a file.
    #
    # Keyword arguments:
    #   title:       - a String to override the default "ruby-prof call stack"
    #                  title of the report.
    #
    #   threshold:   - a float from 0 to 100 that sets the threshold of
    #                  results displayed.
    #                  Default value is 1.0
    #
    #   expansion:   - a float from 0 to 100 that sets the threshold of
    #                  results that are expanded, if the percent_total
    #                  exceeds it.
    #                  Default value is 10.0
    #
    #   application: - a String to override the name of the application,
    #                  as it appears on the report.
    #
    # Also accepts min_percent:, max_percent:, filter_by:, and sort_method:
    # from AbstractPrinter.
    def print(output = STDOUT, title: "ruby-prof call stack", threshold: 1.0,
              expansion: 10.0, application: $PROGRAM_NAME,
              min_percent: 0, max_percent: 100, filter_by: :self_time, sort_method: nil, **)
      @min_percent = min_percent
      @max_percent = max_percent
      @filter_by = filter_by
      @sort_method = sort_method
      @title = title
      @threshold = threshold
      @expansion = expansion
      @application = application
      output << ERB.new(self.template).result(binding)
    end

    def print_stack(output, visited, call_tree, parent_time)
      total_time = call_tree.total_time
      percent_parent = (total_time/parent_time)*100
      percent_total = (total_time/@overall_time)*100
      return unless percent_total > min_percent
      color = self.color(percent_total)
      visible = percent_total >= threshold
      expanded = percent_total >= expansion
      display = visible ? "block" : "none"

      output << "<li class=\"color#{color}\" style=\"display:#{display}\">" << "\n"

      if visited.include?(call_tree)
        output << "<a href=\"#\" class=\"toggle empty\" ></a>" << "\n"
        output << "<span>%s %s</span>" % [link(call_tree.target, true), graph_link(call_tree)] << "\n"
      else
        visited << call_tree

        if call_tree.children.empty?
          output << "<a href=\"#\" class=\"toggle empty\" ></a>" << "\n"
        else
          visible_children = call_tree.children.any?{|ci| (ci.total_time/@overall_time)*100 >= threshold}
          image = visible_children ? (expanded ? "minus" : "plus") : "empty"
          output << "<a href=\"#\" class=\"toggle #{image}\" ></a>" << "\n"
        end
        output << "<span>%4.2f%% (%4.2f%%) %s %s</span>" % [percent_total, percent_parent,
                                                            link(call_tree.target, false), graph_link(call_tree)] << "\n"

        unless call_tree.children.empty?
          output <<  (expanded ? '<ul>' : '<ul style="display:none">')  << "\n"
          call_tree.children.sort_by{|c| -c.total_time}.each do |child_call_tree|
            print_stack(output, visited, child_call_tree, total_time)
          end
          output << '</ul>' << "\n"
        end

        visited.delete(call_tree)
      end
      output << '</li>' << "\n"
    end

    def name(call_tree)
      method = call_tree.target
      method.full_name
    end

    def link(method, recursive)
      method_name = "#{recursive ? '*' : ''}#{method.full_name}"
      if method.source_file.nil?
        h method_name
      else
        file = File.expand_path(method.source_file)
       "<a href=\"file://#{file}##{method.line}\">#{h method_name}</a>"
      end
    end

    def graph_link(call_tree)
      total_calls = call_tree.target.called
      totals = total_calls.to_s
      "[#{call_tree.called} calls, #{totals} total]"
    end

    def method_href(method)
      h(method.full_name.gsub(/[><#\.\?=:]/,"_"))
    end

    def total_time(call_trees)
      sum(call_trees.map{|ci| ci.total_time})
    end

    def sum(a)
      a.inject(0.0){|s,t| s+=t}
    end

    def dump(ci)
      $stderr.printf "%s/%d t:%f s:%f w:%f  \n", ci, ci.object_id, ci.total_time, ci.self_time, ci.wait_time
    end

    def color(p)
      case i = p.to_i
      when 0..5
        "01"
      when 5..10
        "05"
      when 100
        "9"
      else
        "#{i/10}"
      end
    end

    attr_reader :application, :title, :threshold, :expansion

    def arguments
      ARGV.join(' ')
    end

    def base64_image
      @data ||= begin
        file = open_asset('call_stack_printer.png')
        Base64.encode64(file).gsub(/\n/, '')
      end
    end

    def template
      open_asset('call_stack_printer.html.erb')
    end
  end
end
