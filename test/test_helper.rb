# encoding: UTF-8

# Make RubyMine happy
if ENV["RM_INFO"] || ENV["TEAMCITY_VERSION"]
  gem 'win32console'
  gem 'minitest-reporters'
  require 'minitest/reporters'
  MiniTest::Unit.runner = MiniTest::SuiteRunner.new
  MiniTest::Unit.runner.reporters << MiniTest::Reporters::RubyMineReporter.new
end

# To make testing/debugging easier, test within this source tree versus an installed gem

dir = File.dirname(__FILE__)
root = File.expand_path(File.join(dir, '..'))
lib = File.expand_path(File.join(root, 'lib'))
ext = File.expand_path(File.join(root, 'ext', 'ruby_prof'))

$LOAD_PATH << lib
$LOAD_PATH << ext

require 'ruby-prof'
require 'test/unit'
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
  
  if RUBY_VERSION < '1.9'
    PARENT = Object
  else
    PARENT = BasicObject
  end

end