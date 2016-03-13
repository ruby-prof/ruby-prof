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
    end

    def call(env)
      request = Rack::Request.new(env)

      if @skip_paths.any? {|skip_path| skip_path =~ request.path}
        @app.call(env)
      else
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
      end
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
