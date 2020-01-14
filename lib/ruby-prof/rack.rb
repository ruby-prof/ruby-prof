# encoding: utf-8
require 'tmpdir'

module Rack
  class RubyProf
    def initialize(app, options = {})
      @app = app

      options[:min_percent] ||= 1

      options[:path] ||= Dir.tmpdir
      FileUtils.mkdir_p(options[:path])

      @skip_paths = options[:skip_paths] || [%r{^/assets}, %r{\.(css|js|png|jpeg|jpg|gif)$}]
      @only_paths = options[:only_paths]

      @max_requests = options[:max_requests]

      @options = options
    end

    def call(env)
      request = Rack::Request.new(env)

      if should_profile?(request.path)
        profiler.resume
        begin
          result = @app.call(env)
        ensure
          profiler.pause
        end

        if profiler.max_requests_reached?
          prefix = if aggregate_requests?
              nil
            else
              request.path.gsub('/', '-')[1..-1]
            end

          profiler.print!(prefix)
          delete_profiler!
        end

        result
      else
        @app.call(env)
      end
    end

    private

    class RackProfiler
      def initialize(options)
        @options = options

        @profile = ::RubyProf::Profile.new(profiling_options)
        @profile.start
        @profile.pause

        @printer_klasses = options[:printers] || default_printers

        @tmpdir = options[:path]

        @max_requests = options[:max_requests] || 1
        @requests_count = 0

        @printed = false
        # if running across multiple requests, we want to make sure that the
        # ongoing profile is not lost if the process shuts down before the
        # max request count is reached
        ObjectSpace.define_finalizer(self, proc { print! })
      end

      def resume
        @profile.resume
      end

      def pause
        @profile.pause
        @requests_count += 1
      end

      def max_requests_reached?
        @requests_count >= @max_requests
      end

      def print!(prefix = nil)
        return false if @printed || @requests_count == 0

        data = @profile.stop

        prefix ||= "multi-requests-#{@requests_count}"

        @printer_klasses.each do |printer_klass, base_name|
          printer = printer_klass.new(data)

          if base_name.respond_to?(:call)
            base_name = base_name.call
          end

          if printer_klass == ::RubyProf::MultiPrinter \
              || printer_klass == ::RubyProf::CallTreePrinter
            printer.print(@options.merge(:profile => "#{prefix}-#{base_name}"))
          else
            file_name = ::File.join(@tmpdir, "#{prefix}-#{base_name}")
            ::File.open(file_name, 'wb') do |file|
              printer.print(file, @options)
            end
          end
        end

        @printed = true
      end

      private

      def profiling_options
        options = {}
        options[:measure_mode] = ::RubyProf.measure_mode
        options[:exclude_threads] =
          if @options[:ignore_existing_threads]
            Thread.list.select{|t| t != Thread.current}
          else
            ::RubyProf.exclude_threads
          end
        if @options[:request_thread_only]
          options[:include_threads] = [Thread.current]
        end
        if @options[:merge_fibers]
          options[:merge_fibers] = true
        end
        options
      end

      def default_printers
        {::RubyProf::FlatPrinter => 'flat.txt',
         ::RubyProf::GraphPrinter => 'graph.txt',
         ::RubyProf::GraphHtmlPrinter => 'graph.html',
         ::RubyProf::CallStackPrinter => 'call_stack.html'}
      end
    end

    def profiler
      if aggregate_requests?
        @@_shared_profiler ||= RackProfiler.new(@options)
      else
        @_profiler ||= RackProfiler.new(@options)
      end
    end

    def delete_profiler!
      if aggregate_requests?
        @@_shared_profiler.print! if @@_shared_profiler
        @@_shared_profiler = nil
      else
        @_profiler = nil
      end
    end

    def aggregate_requests?
      !@max_requests.nil?
    end

    def should_profile?(path)
      return false if paths_match?(path, @skip_paths)

      @only_paths ? paths_match?(path, @only_paths) : true
    end

    def paths_match?(path, paths)
      paths.any? { |skip_path| skip_path =~ path }
    end
  end
end
