
module RubyProf
  # Generates flat[link:files/examples/flat_txt.html] profile reports as text.
  # To use the flat printer with line numbers:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::FlatPrinterWithLineNumbers.new(result)
  #   printer.print(STDOUT, {})
  #
  class FlatPrinterWithLineNumbers < FlatPrinter

    def print_methods(thread_id, methods)
      # Get total time
      toplevel = methods.max
      total_time = toplevel.total_time
      if total_time == 0
        total_time = 0.01
      end

      # Now sort methods by largest self time,
      # not total time like in other printouts
      methods = methods.sort do |m1, m2|
        m1.self_time <=> m2.self_time
      end.reverse

      @output << "Thread ID: %d\n" % thread_id
      @output << "Total: %0.6f\n" % total_time
      @output << "\n"
      @output << " %self     total     self     wait    child    calls  name\n"
      sum = 0
      methods.each do |method|
        self_percent = (method.self_time / total_time) * 100
        next if self_percent < min_percent

        sum += method.self_time
        #self_time_called = method.called > 0 ? method.self_time/method.called : 0
        #total_time_called = method.called > 0? method.total_time/method.called : 0

        @output << "%6.2f  %8.2f %8.2f %8.2f %8.2f %8d  %s " % [
                      method.self_time / total_time * 100, # %self
                      method.total_time,                   # total
                      method.self_time,                    # self
                      method.wait_time,                    # wait
                      method.children_time,                # children
                      method.called,                       # calls
                      method_name(method),                 # name
                  ]
         if method.source_file != 'ruby_runtime'
           @output << "  %s:%s" % [File.expand_path(method.source_file), method.line]
         end
         @output << "\n\tcalled from: "

         # make sure they're unique
         method.call_infos.map{|ci|
           if ci.parent && ci.parent.target.source_file != 'ruby_runtime'
              [method_name(ci.parent.target), File.expand_path(ci.parent.target.source_file), ci.parent.target.line]
           else
              nil
           end
         }.compact.uniq.each{|args|
             @output << " %s (%s:%s) " % args
         }
         @output << "\n\n"
      end
    end
  end
end

