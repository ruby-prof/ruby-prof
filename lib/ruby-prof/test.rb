# Now load ruby-prof and away we go
require 'fileutils'
require 'ruby-prof'
require 'benchmark'

module RubyProf
  module Test
    PROFILE_OPTIONS = {
      :measure_modes => [RubyProf::PROCESS_TIME],
      :count => 10,
      :printers => [RubyProf::FlatPrinter, RubyProf::GraphHtmlPrinter],
      :min_percent => 0.05,
      :output_dir => Dir.pwd }

    def output_dir
      PROFILE_OPTIONS[:output_dir]
    end
          
    def run(result)
      return if @method_name.to_s == "default_test"

      yield(self.class::STARTED, name)
      @_result = result
      run_warmup
      PROFILE_OPTIONS[:measure_modes].each do |measure_mode|
        data = run_profile(measure_mode)
        report_profile(data, measure_mode)
        result.add_run
      end
      yield(self.class::FINISHED, name)
    end

    def run_test
      begin
        setup
        yield
      rescue ::Test::Unit::AssertionFailedError => e
        add_failure(e.message, e.backtrace)
      rescue StandardError, ScriptError
        add_error($!)
      ensure
        begin
          teardown
        rescue ::Test::Unit::AssertionFailedError => e
          add_failure(e.message, e.backtrace)
        rescue StandardError, ScriptError
          add_error($!)
        end
      end
    end

    def run_warmup
      print "\n#{self.class.name}##{method_name}"

      run_test do
        bench = Benchmark.realtime do
          __send__(@method_name)
        end
        puts " (%.2fs warmup)" % bench
      end
    end

    def run_profile(measure_mode)
      RubyProf.measure_mode = measure_mode

      print '  '
      PROFILE_OPTIONS[:count].times do |i|
        run_test do
          begin
            print '.'
            $stdout.flush
            GC.disable

            RubyProf.resume do
              __send__(@method_name)
            end
          ensure
            GC.enable
          end
        end
      end

      data = RubyProf.stop
      bench = data.threads.values.inject(0) do |total, method_infos|
        top = method_infos.sort.last
        total += top.total_time
        total
      end

      puts "\n  #{measure_mode_name(measure_mode)}: #{format_profile_total(bench, measure_mode)}\n"

      data
    end

    def format_profile_total(total, measure_mode)
      case measure_mode
        when RubyProf::PROCESS_TIME, RubyProf::WALL_TIME
          "%.2f seconds" % total
        when RubyProf::MEMORY
          "%.2f kilobytes" % total
        when RubyProf::ALLOCATIONS
          "%d allocations" % total
        else
          "%.2f #{measure_mode}"
      end
    end

    def report_profile(data, measure_mode)
      PROFILE_OPTIONS[:printers].each do |printer_klass|
        printer = printer_klass.new(data)
        
        # Makes sure the output directory exits
        FileUtils.mkdir_p(output_dir)

        # Open the file
        file_name = report_filename(printer, measure_mode)

        File.open(file_name, 'wb') do |file|
          printer.print(file, PROFILE_OPTIONS)
        end
      end
    end

    # The report filename is test_name + measure_mode + report_type
    def report_filename(printer, measure_mode)
      suffix =
        case printer
          when RubyProf::FlatPrinter; 'flat.txt'
          when RubyProf::GraphPrinter; 'graph.txt'
          when RubyProf::GraphHtmlPrinter; 'graph.html'
          when RubyProf::CallTreePrinter; 'tree.txt'
          else printer.to_s.downcase
        end

      "#{output_dir}/#{method_name}_#{measure_mode_name(measure_mode)}_#{suffix}"
    end

    def measure_mode_name(measure_mode)
      case measure_mode
        when RubyProf::PROCESS_TIME; 'process_time'
        when RubyProf::WALL_TIME; 'wall_time'
        when RubyProf::MEMORY; 'memory'
        when RubyProf::ALLOCATIONS; 'allocations'
        else "measure#{measure_mode}"
      end
    end
  end
end