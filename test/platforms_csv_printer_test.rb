require File.expand_path('../test_helper', __FILE__)
require 'rubygems'
require 'ruby-prof'
require 'stringio'
require 'csv'

class PlatformsCSVTestClass

	def func1()
		func2(1)	
		func3()
		func2(0)
	end
	
	def func2(switch)
		if switch == 1
			func4()
		else 
			1000.times do |i|
				String.new("hello")
				rand(i)
			end	
		end
	end
	
	def func3()
		10000.times do |i|
			rand(i)
		end
	end		
	
	def func4()
		5000.times do |i|
			rand(i)
		end
	end
end

class PlatformsCSVTest < Test::Unit::TestCase

  def test_csv_output
	RubyProf.start
	PlatformsCSVTestClass.new.func1()
	result = RubyProf.stop

    output = ENV['SHOW_RUBY_PROF_PRINTER_OUTPUT'] == "1" ? STDOUT : StringIO.new('')

	printer = RubyProf::PlatformsCSVPrinter.new(result)
	printer.print(output)	

	data = CSV.parse(output.string)

	assert(data.length > 8)
	
	# func1 has invocation count 1
	func1_row = data.select {|item| item[0].start_with? "PlatformsCSVTestClass#func1"} [0]
	assert(func1_row != nil)
	assert_nothing_raised ArgumentError do
		Float(func1_row[2].strip)
	end
	assert_nothing_raised ArgumentError do
		Float(func1_row[3].strip)
	end
	assert_nothing_raised ArgumentError do
		Float(func1_row[4].strip)
	end
	#func1 has invocation count 1
	assert(func1_row[5].strip == "1")
	#func1 has level 2
	assert(func1_row[6].strip == "2")
	
	# This is the problem:
	# func2 has invocation count 2
	func2_row = data.select {|item| item[0].start_with? "PlatformsCSVTestClass#func2"} [0]
	assert(func2_row != nil)
	assert(func2_row[5].strip == "2")

	#func1 time = func2 time + func3 time
	func3_row = data.select {|item| item[0].start_with? "PlatformsCSVTestClass#func3"} [0]
	func1_time = func1_row[2].to_i
	func2_time = func2_row[2].to_i
	func3_time = func3_row[2].to_i
	assert(func1_time = func2_time + func3_time)
	
  end
end
