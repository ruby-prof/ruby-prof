#!/usr/bin/env ruby
# encoding: UTF-8

# Generates example reports for all ruby-prof printers.
# Usage: ruby docs/public/examples/generate_reports.rb

# To make testing/debugging easier test within this source tree versus an installed gem
require 'bundler/setup'

# Add ext directory to load path to make it easier to test locally built extensions
ext_path = File.expand_path(File.join(__dir__, '..', '..', '..', 'ext', 'ruby_prof'))
$LOAD_PATH.unshift(ext_path)

require 'fileutils'
require 'stringio'
require 'uri'
require 'ruby-prof'
require_relative 'example'

output_dir = File.join(File.dirname(__FILE__), "reports")
FileUtils.mkdir_p(output_dir)

def sanitize_local_file_links(path)
  content = File.read(path)
  content.gsub!(%r{href="file://[^"]*/docs/public/examples/([^"#]+)#\d+"}, 'href="../\1"')
  content.gsub!(%r{title=".*?/docs/public/examples/([^":]+):\d+"}, 'title="\1"')
  content.gsub!(%r{href="file://[^"]+"}, 'href="#"')
  content.gsub!(%r{title="[^"]*(?:<internal:|&lt;internal:)[^"]+"}, 'title="internal"')
  File.write(path, content)
end

result = RubyProf::Profile.profile(measure_mode: RubyProf::WALL_TIME) do
  run_example
end

# Flame Graph
File.open(File.join(output_dir, "flame_graph.html"), "wb") do |f|
  RubyProf::FlameGraphPrinter.new(result).print(f)
end

# Call Stack
File.open(File.join(output_dir, "call_stack.html"), "wb") do |f|
  RubyProf::CallStackPrinter.new(result).print(f)
end
sanitize_local_file_links(File.join(output_dir, "call_stack.html"))

# Graph HTML
File.open(File.join(output_dir, "graph.html"), "wb") do |f|
  RubyProf::GraphHtmlPrinter.new(result).print(f)
end
sanitize_local_file_links(File.join(output_dir, "graph.html"))

# Graph (text)
File.open(File.join(output_dir, "graph.txt"), "wb") do |f|
  RubyProf::GraphPrinter.new(result).print(f)
end

# Flat
File.open(File.join(output_dir, "flat.txt"), "wb") do |f|
  RubyProf::FlatPrinter.new(result).print(f)
end

# Call Info
File.open(File.join(output_dir, "call_info.txt"), "wb") do |f|
  RubyProf::CallInfoPrinter.new(result).print(f)
end

# Dot
dot_io = StringIO.new
RubyProf::DotPrinter.new(result).print(dot_io)
dot_content = dot_io.string
File.open(File.join(output_dir, "graph.dot"), "wb") do |f|
  f << dot_content
end

# Graphviz Online viewer with dot content embedded in URL
viewer_url = "https://dreampuf.github.io/GraphvizOnline/?engine=dot#" + URI.encode_uri_component(dot_content)
File.open(File.join(output_dir, "graphviz_viewer.html"), "wb") do |f|
  f << %(<html><head><meta http-equiv="refresh" content="0;url=#{viewer_url}"></head></html>)
end

# Call Tree (calltree format)
RubyProf::CallTreePrinter.new(result).print(path: output_dir, profile: "profile")
# Rename PID-based filename to a stable name
Dir.glob(File.join(output_dir, "callgrind.out.*")).each do |f|
  FileUtils.mv(f, File.join(output_dir, "callgrind.out"))
end

puts "Reports written to #{output_dir}/"
Dir.glob(File.join(output_dir, "*")).sort.each do |f|
  puts "  #{File.basename(f)}"
end
