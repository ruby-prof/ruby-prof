# encoding: utf-8
require 'tmpdir'

module Rack
  class RubyProf
    def initialize(app, options = {})
      @app = app
      @options = options
      @options[:min_percent] ||= 1

      @tmpdir = options[:path] || Dir.tmpdir
      FileUtils.mkdir_p(@tmpdir)

      @printer_klasses = @options[:printers]  || {::RubyProf::FlatPrinter => 'flat.txt',
                                                  ::RubyProf::GraphPrinter => 'graph.txt',
                                                  ::RubyProf::GraphHtmlPrinter => 'graph.html',
                                                  ::RubyProf::CallStackPrinter => 'call_stack.html'}

      @skip_paths = options[:skip_paths] || [%r{^/assets}, %r{\.(css|js|png|jpeg|jpg|gif)$}]
      @only_paths = options[:only_paths]
    end

    def call(env)
      request = Rack::Request.new(env)

      if should_profile?(request.path)
        begin
          result = nil
          data = ::RubyProf::Profile.profile(profiling_options) do
            result = @app.call(env)
          end

          path = request.path.gsub('/', '-')
          path.slice!(0)

          print(data, path)
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

    def print(data, path)
      @printer_klasses.each do |printer_klass, base_name|
        printer = printer_klass.new(data)

        if base_name.respond_to?(:call)
          base_name = base_name.call
        end

        if printer_klass == ::RubyProf::MultiPrinter
          printer.print(@options.merge(:profile => "#{path}-#{base_name}"))
        elsif printer_klass == ::RubyProf::CallTreePrinter
          printer.print(@options.merge(:profile => "#{path}-#{base_name}"))
        else
          file_name = ::File.join(@tmpdir, "#{path}-#{base_name}")
          ::File.open(file_name, 'wb') do |file|
            printer.print(file, @options)
          end
        end
      end
    end
  end
end
