# encoding: UTF-8

# Make RubyMine happy
require "rubygems"
gem "minitest"

if ENV["RM_INFO"] || ENV["TEAMCITY_VERSION"]
  if RUBY_PLATFORM =~ /(win32|mingw)/
    gem "win32console"
  end
  gem "minitest-reporters"
  require 'minitest/reporters'
  MiniTest::Reporters.use!
end

require "minitest/pride" if RUBY_VERSION == "1.9.3"

# To make testing/debugging easier, test within this source tree versus an installed gem
dir = File.dirname(__FILE__)
root = File.expand_path(File.join(dir, '..'))
lib = File.expand_path(File.join(root, 'lib'))
ext = File.expand_path(File.join(root, 'ext', 'ruby_prof'))

$LOAD_PATH << lib
$LOAD_PATH << ext

require 'ruby-prof'
require 'minitest/autorun'

class TestCase < Minitest::Test
  # I know this sucks, but ...
  def assert_nothing_raised(*)
    yield
  end

  def before_setup
    # make sure to exclude all threads except the one running the test
    # minitest allocates a thread pool and they would otherwise show
    # up in the profile data, breaking tests randomly
    RubyProf.exclude_threads = Thread.list.select{|t| t != Thread.current}
  end

  def after_teardown
    # reset exclude threads after testing
    RubyProf.exclude_threads = nil
  end
end

require File.expand_path('../prime', __FILE__)

# Some classes used in measurement tests
module RubyProf
  class C1
    def C1.hello
      sleep(0.1)
    end

    def hello
      sleep(0.2)
    end
  end

  module M1
    def hello
      sleep(0.3)
    end
  end

  class C2
    include M1
    extend M1
  end

  class C3
    def hello
      sleep(0.4)
    end
  end

  module M4
    def hello
      sleep(0.5)
    end
  end

  module M5
    include M4
    def goodbye
      hello
    end
  end

  class C6
    include M5
    def test
      goodbye
    end
  end

  class C7
    def self.busy_wait
      t = Time.now.to_f
      while Time.now.to_f - t < 0.1; end
    end

    def self.sleep_wait
      sleep 0.1
    end

    def busy_wait
      t = Time.now.to_f
      while Time.now.to_f - t < 0.2; end
    end

    def sleep_wait
      sleep 0.2
    end
  end

  module M7
    def busy_wait
      t = Time.now.to_f
      while Time.now.to_f - t < 0.3; end
    end

    def sleep_wait
      sleep 0.3
    end
  end

  class C8
    include M7
    extend M7
  end

  def self.ruby_major_version
    match = RUBY_VERSION.match(/(\d)\.(\d)/)
    return Integer(match[1])
  end

  def self.ruby_minor_version
    match = RUBY_VERSION.match(/(\d)\.(\d)/)
    return Integer(match[2])
  end

  def self.parent_object
    if ruby_major_version == 1 && ruby_minor_version == 8
      Object
    else
      BasicObject
    end
  end

  def self.ruby_2?
    ruby_major_version == 2
  end

  # store printer output in this directory
  def self.tmpdir
    File.expand_path('../../tmp', __FILE__)
  end
end

module MemoryTestHelper
  def memory_test_helper
    result = RubyProf.profile {Array.new}
    total = result.threads.first.methods.inject(0) { |sum, m| sum + m.total_time }
    assert(total < 1_000_000, 'Total should not have subtract overflow error')
    total
  end
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
