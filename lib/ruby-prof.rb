# encoding: utf-8

# Load the C-based binding.
begin
  RUBY_VERSION =~ /(\d+\.\d+\.\d+)/
  require "#{$1}/ruby_prof.so"
rescue LoadError
  require "ruby_prof.so"
end

require 'ruby-prof/version'
require 'ruby-prof/call_info'
require 'ruby-prof/compatibility'
require 'ruby-prof/method_info'
require 'ruby-prof/profile'
require 'ruby-prof/rack'
require 'ruby-prof/thread'

module RubyProf
  autoload :AggregateCallInfo, 'ruby-prof/aggregate_call_info'
  autoload :CallInfoVisitor, 'ruby-prof/call_info_visitor'

  autoload :AbstractPrinter, 'ruby-prof/printers/abstract_printer'
  autoload :CallInfoPrinter, 'ruby-prof/printers/call_info_printer'
  autoload :CallStackPrinter, 'ruby-prof/printers/call_stack_printer'
  autoload :CallTreePrinter, 'ruby-prof/printers/call_tree_printer'
  autoload :DotPrinter, 'ruby-prof/printers/dot_printer'
  autoload :FlatPrinter, 'ruby-prof/printers/flat_printer'
  autoload :FlatPrinterWithLineNumbers, 'ruby-prof/printers/flat_printer_with_line_numbers'
  autoload :GraphHtmlPrinter, 'ruby-prof/printers/graph_html_printer'
  autoload :GraphPrinter, 'ruby-prof/printers/graph_printer'
  autoload :MultiPrinter, 'ruby-prof/printers/multi_printer'

  # Checks if the user specified the clock mode via
  # the RUBY_PROF_MEASURE_MODE environment variable
  def self.figure_measure_mode
    case ENV["RUBY_PROF_MEASURE_MODE"]
    when "wall", "wall_time"
      RubyProf.measure_mode = RubyProf::WALL_TIME
    when "cpu", "cpu_time"
      RubyProf.measure_mode = RubyProf::CPU_TIME
    when "allocations"
      RubyProf.measure_mode = RubyProf::ALLOCATIONS
    when "memory"
      RubyProf.measure_mode = RubyProf::MEMORY
    when "process", "process_time"
      RubyProf.measure_mode = RubyProf::PROCESS_TIME
    when "gc_time"
      RubyProf.measure_mode = RubyProf::GC_TIME
    when "gc_runs"
      RubyProf.measure_mode = RubyProf::GC_RUNS
    else
      # the default is defined in the measure_mode reader
    end
  end
end

RubyProf::figure_measure_mode
