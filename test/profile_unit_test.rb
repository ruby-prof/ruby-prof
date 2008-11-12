#!/usr/bin/env ruby
require 'test/unit'
require 'ruby-prof'

# Need to use wall time for this test due to the sleep calls
RubyProf::measure_mode = RubyProf::WALL_TIME

# --  Tests ----
class ProfileTest < Test::Unit::TestCase
  include RubyProf::Test
  
  def teardown
    profile_dir = output_dir
    
    #file_path = File.join(profile_dir, 'test_profile_profile_test.html')
    #assert(File.exists?(file_path))
  end
  
  def test_profile
    sleep(1)    
  end
end