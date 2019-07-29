# encoding: UTF-8

require "rubygems"
gem "minitest"
require 'singleton'

# To make testing/debugging easier, test within this source tree versus an installed gem
dir = File.dirname(__FILE__)
root = File.expand_path(File.join(dir, '..'))
lib = File.expand_path(File.join(root, 'lib'))
ext = File.expand_path(File.join(root, 'ext', 'ruby_prof'))

$LOAD_PATH << lib
$LOAD_PATH << ext

require 'ruby-prof'

# Disable minitest parallel tests. The problem is the thread switching will cahnge test results
# (self vs wait time)
ENV["N"] = "0"
require 'minitest/autorun'

class TestCase < Minitest::Test
end

module PrinterTestHelper
  Metrics = Struct.new(:name, :total, :self_t, :wait, :child, :calls)
  class Metrics
    def pp
      "%s[total: %.2f, self: %.2f, wait: %.2f, child: %.2f, calls: %s]" %
        [name, total, self_t, wait, child, calls]
    end
  end

  Entry = Struct.new(:total_p, :self_p, :metrics, :parents, :children)
  class Entry
    def child(name)
      children.detect{|m| m.name == name}
    end

    def parent(name)
      parents.detect{|m| m.name == name}
    end

    def pp
      res = ""
      res << "NODE (total%%: %.2f, self%%: %.2f) %s\n" % [total_p, self_p, metrics.pp]
      res << "  PARENTS:\n"
      parents.each {|m| res << "    " + m.pp << "\n"}
      res << "  CHILDREN:\n"
      children.each {|m| res << "    " + m.pp << "\n"}
      res
    end
  end

  class MetricsArray < Array
    def metrics_for(name)
      detect {|e| e.metrics.name == name}
    end

    def pp(io = STDOUT)
      entries = map do |e|
        begin
          e.pp
        rescue
          puts $!.message + e.inspect
          ""
        end
      end
      io.puts entries.join("--------------------------------------------------\n")
    end

    def self.parse(str)
      res = new
      entry = nil
      relatives = []
      state = :preamble

      str.each_line do |l|
        line = l.chomp.strip
        if line =~ /-----/
          if state == :preamble
            state = :parsing_parents
            entry = Entry.new
          elsif state == :parsing_parents
            entry = Entry.new
          elsif state == :parsing_children
            entry.children = relatives
            res << entry
            entry = Entry.new
            relatives = []
            state = :parsing_parents
          end
        elsif line =~ /^\s*$/ || line =~ /indicates recursively called methods/
          next
        elsif state != :preamble
          elements = line.split(/\s+/)
          method = elements.pop
          numbers = elements[0..-2].map(&:to_f)
          metrics = Metrics.new(method, *numbers[-4..-1], elements[-1])
          if numbers.size == 6
            entry.metrics = metrics
            entry.total_p = numbers[0]
            entry.self_p = numbers[1]
            entry.parents = relatives
            entry.children = relatives = []
            state = :parsing_children
            res << entry
          else
            relatives << metrics
          end
        end
      end
      res
    end
  end
end
