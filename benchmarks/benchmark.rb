require 'ruby-prof'
require 'benchmark'
require 'benchmark/ips'

def go
end

puts Benchmark.realtime {
 RubyProf.profile do
  100000.times { go }
 end
}

for n in [5, 100] do
 n.times { Thread.new { sleep }}
 puts Benchmark.realtime {
  RubyProf.profile do
   100000.times { go }
  end
 }
end


Benchmark.ips do |x|
 x.config(:time => 3, :warmup => 1)
 x.report("with ruby prof:") do
  RubyProf.profile do
   100000.times { go }
  end
 end
 x.report("without ruby prof:") do
  100000.times { go }
 end
 x.report("profile") do
  RubyProf.profile do
  end
 end
 x.compare!
end
