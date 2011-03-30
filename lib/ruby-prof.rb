# require the .so (ext) file...

me = File.dirname(__FILE__) + '/'
begin
  # fat binaries
  require "#{me}/#{RUBY_VERSION[0..2]}/ruby_prof"
rescue Exception
  require "#{me}/../ext/ruby_prof/ruby_prof"
end

# have to load them by hand since we don't want to load 'unprof'

for file in ['abstract_printer', 'result', 'method_info', 'call_info', 'aggregate_call_info', 'flat_printer', 'flat_printer_with_line_numbers', 
 'graph_printer', 'graph_html_printer', 'call_tree_printer', 'call_stack_printer', 'multi_printer', 'dot_printer', 'symbol_to_proc', # for 1.8's backward compatible benefit
 'rack']

 require File.dirname(__FILE__) + '/ruby-prof/' + file
end

module RubyProf
  # See if the user specified the clock mode via
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
