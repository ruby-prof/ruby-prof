# encoding: utf-8
require 'tmpdir'

module Rack
  class RubyProf
    def initialize(app, path: Dir.tmpdir, printers: nil, skip_paths: nil,
                   only_paths: nil, merge_fibers: false,
                   measure_mode: ::RubyProf::WALL_TIME, track_allocations: false,
                   exclude_common: false, ignore_existing_threads: false,
                   request_thread_only: false, min_percent: 1,
                   sort_method: :total_time)
      @app = app

      @tmpdir = path
      FileUtils.mkdir_p(@tmpdir)

      @printer_klasses = printers || {::RubyProf::FlatPrinter => 'flat.txt',
                                      ::RubyProf::GraphPrinter => 'graph.txt',
                                      ::RubyProf::GraphHtmlPrinter => 'graph.html',
                                      ::RubyProf::CallStackPrinter => 'call_stack.html'}

      @skip_paths = skip_paths || [%r{^/assets}, %r{\.(css|js|png|jpeg|jpg|gif)$}]
      @only_paths = only_paths
      @merge_fibers = merge_fibers
      @measure_mode = measure_mode
      @track_allocations = track_allocations
      @exclude_common = exclude_common
      @ignore_existing_threads = ignore_existing_threads
      @request_thread_only = request_thread_only
      @min_percent = min_percent
      @sort_method = sort_method
    end

    def call(env)
      request = Rack::Request.new(env)

      if should_profile?(request.path)
        begin
          result = nil
          profile = ::RubyProf::Profile.profile(**profiling_options) do
            result = @app.call(env)
          end

          if @merge_fibers
            profile.merge!
          end


          path = request.path.gsub('/', '-')
          path.slice!(0)

          print(profile, path)
          result
        end
      else
        @app.call(env)
      end
    end

    private

    def should_profile?(path)
      return false if paths_match?(path, @skip_paths)

      @only_paths ? paths_match?(path, @only_paths) : true
    end

    def paths_match?(path, paths)
      paths.any? { |skip_path| skip_path =~ path }
    end

    def profiling_options
      result = {}
      result[:measure_mode] = @measure_mode
      result[:track_allocations] = @track_allocations
      result[:exclude_common] = @exclude_common

      if @ignore_existing_threads
        result[:exclude_threads] = Thread.list.select {|thread| thread != Thread.current}
      end

      if @request_thread_only
        result[:include_threads] = [Thread.current]
      end

      result
    end

    def print_options
      {min_percent: @min_percent, sort_method: @sort_method}
    end

    def print(profile, path)
      @printer_klasses.each do |printer_klass, base_name|
        printer = printer_klass.new(profile)

        if base_name.respond_to?(:call)
          base_name = base_name.call
        end

        if printer_klass == ::RubyProf::MultiPrinter
          printer.print(profile: "#{path}-#{base_name}", **print_options)
        elsif printer_klass == ::RubyProf::CallTreePrinter
          printer.print(profile: "#{path}-#{base_name}", **print_options)
        else
          file_name = ::File.join(@tmpdir, "#{path}-#{base_name}")
          ::File.open(file_name, 'wb') do |file|
            printer.print(file, **print_options)
          end
        end
      end
    end
  end
end
