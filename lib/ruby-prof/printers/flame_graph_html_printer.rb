# encoding: utf-8
require 'erb'

module RubyProf
  class FlameGraphHtmlPrinter < AbstractPrinter
    include ERB::Util

    def setup_options(options={})
      super(options)

      ref = 'tmpl.html.erb'
      template = read_asset(ref)
      @erb = ERB.new(template)
      @erb.filename = ref
    end

    def print(output=STDOUT, options={})
      @output = output
      setup_options(options)

      str = @erb.result(binding)
      @output << str.split("\n").map(&:rstrip).join("\n")
      @output << "\n"
    end

    private

    def css_libraries_html
      read_asset('lib.css.html')
    end

    def js_libraries_html
      read_asset('lib.js.html')
    end

    def js_code_html
      read_asset('page.js.html')
    end

    def js_data_html
      "<script type=\"text/javascript\">\n\n" \
        "var data = #{data_json};\n\n" \
        "</script>\n"
    end

    def data_json
      StringIO.new.tap { |strio|
        jp = FlameGraphJsonPrinter.new(@result)
        jp.print(strio, @options)
      }.string
    end

    def read_asset(ref)
      base_path = File.expand_path('../../assets', __FILE__)
      file_path = File.join(base_path, "flame_graph_printer.#{ref}")
      File.open(file_path, 'rb').read.strip.untaint
    end
  end
end
