# encoding: utf-8
require 'tmpdir'

module Rack
  class RubyProf
    def initialize(app, options = {})
      @app = app
      @options = options
      @options[:min_percent] ||= 0.01
      @tmpdir = options[:path] || Dir.tmpdir
    end

    def call(env)
      ::RubyProf::Profile.start
      result = @app.call(env)
      data = ::RubyProf.stop

      print(data)
      result
    end

    def print(data)
      printers = {::RubyProf::FlatPrinter => ::File.join(@tmpdir, 'profile.txt'),
                  ::RubyProf::GraphHtmlPrinter => ::File.join(@tmpdir, 'profile.html')}

      printers.each do |printer_klass, file_name|
        printer = printer_klass.new(data)
        ::File.open(file_name, 'wb') do |file|
          printer.print(file, @options)
        end
      end
    end
  end
end