module Rack
  class RubyProf
    def initialize(app)
      @app = app
    end

    def call(env)
      ::RubyProf.start
      result = @app.call(env)
      data = ::RubyProf.stop

      print(data)
      result
    end

    def print
      printers = {::RubyProf::FlatPrinter => 'c:/temp/profile.txt',
                  ::RubyProf::GraphHtmlPrinter => 'c:/temp/profile.html'}

      printers.each do |printer_klass, file_name|
        printer = printer_klass.new(result)
          ::File.open(file_name, 'wb') do |file|
          printer.print(file, :min_percent => 0.00000001 )
        end
      end
    end
  end
end