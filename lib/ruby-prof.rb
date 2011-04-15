# require the .so file...
require  File.dirname(__FILE__) + "/../ext/ruby_prof/ruby_prof"

module RubyProf
  
  if RUBY_VERSION < '1.8.7'
    require File.dirname(__FILE__) + '/ruby-prof/symbol_to_proc'
  end
  
  def self.camelcase(phrase)
    ('_' + phrase).gsub(/_([a-z])/){|b| b[1..1].upcase}
  end
  
  lib_dir = File.dirname(__FILE__) + '/ruby-prof/'
  
  for file in ['abstract_printer', 'aggregate_call_info', 'flat_printer', 'flat_printer_with_line_numbers', 
    'graph_printer', 'graph_html_printer', 'call_tree_printer', 'call_stack_printer', 'multi_printer', 'dot_printer']
    autoload camelcase(file), lib_dir + file
  end

  # A few need to be loaded manually their classes were already defined by the .so file so autoload won't work for them.
  # plus we need them anyway
  for name in ['result', 'method_info', 'call_info']
    require lib_dir + name
  end
  
  require File.dirname(__FILE__) + '/ruby-prof/rack' # do we even need to load this every time?
  
  # we don't require unprof.rb, as well, purposefully
  
  
  # Checks if the user specified the clock mode via
  # the RUBY_PROF_MEASURE_MODE environment variable
  def self.figure_measure_mode
    case ENV["RUBY_PROF_MEASURE_MODE"]
    when "wall" || "wall_time"
      RubyProf.measure_mode = RubyProf::WALL_TIME
    when "cpu" || "cpu_time"
      if ENV.key?("RUBY_PROF_CPU_FREQUENCY")
        RubyProf.cpu_frequency = ENV["RUBY_PROF_CPU_FREQUENCY"].to_f
      else
        begin
          open("/proc/cpuinfo") do |f|
            f.each_line do |line|
              s = line.slice(/cpu MHz\s*:\s*(.*)/, 1)
              if s
                RubyProf.cpu_frequency = s.to_f * 1000000
                break
              end
            end
          end
        rescue Errno::ENOENT
        end
      end
      RubyProf.measure_mode = RubyProf::CPU_TIME
    when "allocations"
      RubyProf.measure_mode = RubyProf::ALLOCATIONS
    when "memory"
      RubyProf.measure_mode = RubyProf::MEMORY
    else
      # the default...
      RubyProf.measure_mode = RubyProf::PROCESS_TIME
    end
  end
end

RubyProf::figure_measure_mode
