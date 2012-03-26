# encoding: utf-8
require 'tmpdir'

module Rack
  class RubyProf
    def initialize(app, options = {})
      @app = app
      @options = options
      @options[:min_percent] ||= 1
      @tmpdir = options[:path] || Dir.tmpdir
      @printer_klasses = {::RubyProf::FlatPrinter => 'flat.txt',
                          ::RubyProf::GraphPrinter => 'graph.txt',
                          ::RubyProf::GraphHtmlPrinter => 'graph.html',
                          ::RubyProf::CallStackPrinter => 'call_stack.html'}
    end

    def call(env)
      result = nil
      data = ::RubyProf::Profile.profile do
        result = @app.call(env)
      end

      request = Rack::Request.new(env)
      path = request.path.gsub('/', '-')
      path.slice!(0)

      print(data, path)
      result
    end

    def print(data, path)
      @printer_klasses.each do |printer_klass, base_name|
        printer = printer_klass.new(data)
        file_name = ::File.join(@tmpdir, "#{path}-#{base_name}")
        ::File.open(file_name, 'wb') do |file|
          printer.print(file, @options)
        end
      end
    end
  end
end