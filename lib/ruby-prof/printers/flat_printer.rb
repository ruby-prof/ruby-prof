# encoding: utf-8

module RubyProf
  # Generates flat[link:files/examples/flat_txt.html] profile reports as text.
  # To use the flat printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::FlatPrinter.new(result)
  #   printer.print(STDOUT, {})
  #
  class FlatPrinter < AbstractPrinter
    # Print a flat profile report to the provided output.
    #
    # output - Any IO object, including STDOUT or a file.
    # The default value is STDOUT.
    #
    # options - Hash of print options.  See #setup_options
    # for more information.
    #
    def print(output = STDOUT, options = {})
      @output = output
      # Now sort methods by largest self time by default,
      # not total time like in other printouts
      options[:sort_method] ||= :self_time
      setup_options(options)
      print_threads
    end

    private

    def print_threads
      @result.threads.each do |thread_id, methods|
        print_methods(thread_id, methods)
        @output << "\n" * 2
      end
    end

    def print_methods(thread_id, methods)
      # Get total time
      toplevel = methods.max
      total_time = toplevel.total_time
      if total_time == 0
        total_time = 0.01
      end

      methods = methods.sort_by(&sort_method).reverse

      @output << "Thread ID: %d\n" % thread_id
      @output << "Total: %0.6f\n" % total_time
      @output << "Sort by: #{sort_method}\n"
      @output << "\n"
      @output << " %self     total     self     wait    child    calls  name\n"

      sum = 0
      methods.each do |method|
        total_percent = (method.total_time / total_time) * 100
        next if total_percent < min_percent

        sum += method.self_time
        #self_time_called = method.called > 0 ? method.self_time/method.called : 0
        #total_time_called = method.called > 0? method.total_time/method.called : 0

        @output << "%6.2f  %8.2f %8.2f %8.2f %8.2f %8d  %s\n" % [
                      method.self_time / total_time * 100, # %self
                      method.total_time,                   # total
                      method.self_time,                    # self
                      method.wait_time,                    # wait
                      method.children_time,                # children
                      method.called,                       # calls
                      method_name(method)                  # name
                  ]
      end
    end
  end
end
