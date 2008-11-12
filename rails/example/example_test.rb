require File.dirname(__FILE__) + '../profile_test_helper'

class ExampleTest < Test::Unit::TestCase
  include RubyProf::Test
  
  def test_stuff
    puts "Test method"
  end
end   
