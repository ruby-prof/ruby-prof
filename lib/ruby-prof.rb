require "ruby_prof.so"

require "ruby-prof/method_info"
require "ruby-prof/call_info"
require "ruby-prof/aggregate_call_info"
require "ruby-prof/flat_printer"
require "ruby-prof/graph_printer"
require "ruby-prof/graph_html_printer"
require "ruby-prof/call_tree_printer"

require "ruby-prof/test"

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
      RubyProf.measure_mode = RubyProf::PROCESS_TIME
    end
  end
end

RubyProf::figure_measure_mode
