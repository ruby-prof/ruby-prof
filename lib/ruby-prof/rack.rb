
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

    def print(data)
      require 'tmpdir' # late require so we load on demand only
      printers = {::RubyProf::FlatPrinter => ::File.join(Dir.tmpdir, 'profile.txt'),
                  ::RubyProf::GraphHtmlPrinter => ::File.join(Dir.tmpdir, 'profile.html')}

      printers.each do |printer_klass, file_name|
        printer = printer_klass.new(data)
        ::File.open(file_name, 'wb') do |file|
          printer.print(file, :min_percent => 0.00000001 )
        end
      end
    end
  end
end