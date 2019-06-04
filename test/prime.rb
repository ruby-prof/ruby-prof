# A silly little test program that finds prime numbers.  It
# is intentionally badly designed to show off the use
# of ruby-prof.
#
# Source from http://people.cs.uchicago.edu/~bomb154/154/maclabs/profilers-lab/

def make_random_array(length, maxnum)
  result = Array.new(length)
  result.each_index do |i|
    result[i] = rand(maxnum)
  end

  result
end

def is_prime(x)
  y = 2
  y.upto(x-1) do |i|
    return false if (x % i) == 0
  end
  true
end

def find_primes(arr)
  result = arr.select do |value|
    is_prime(value)
  end
  result
end

def find_largest(primes)
  largest = primes.first

  # Intentionally use upto for example purposes
  # (upto is also called from is_prime)
  0.upto(primes.length-1) do |i|
    prime = primes[i]
    if prime > largest
      largest = prime
    end
  end
  largest
end

def run_primes(length=10, maxnum=1000)
  # Create random numbers
  random_array = make_random_array(length, maxnum)

  # Find the primes
  primes = find_primes(random_array)

  # Find the largest primes
  find_largest(primes)
end


def test_primes
  start = Process.times
  result = RubyProf.profile do
    run_primes(10000)
  end
  finish = Process.times

  total_time = (finish.utime - start.utime) + (finish.stime - start.stime)

  thread = result.threads.first
  assert_in_delta(total_time, thread.total_time, 0.03)

  methods = result.threads.first.methods.sort.reverse

  # puts methods.map(&:full_name).inspect
  assert_equal(13, methods.length)

  # Check times
  assert_equal("MeasureWallTimeTest#test_primes", methods[0].full_name)
  assert_in_delta(total_time, methods[0].total_time, 0.02)
  assert_in_delta(0.0, methods[0].wait_time, 0.01)
  assert_in_delta(0.0, methods[0].self_time, 0.01)

  assert_equal("Object#run_primes", methods[1].full_name)
  assert_in_delta(total_time, methods[1].total_time, 0.02)
  assert_in_delta(0.0, methods[1].wait_time, 0.01)
  assert_in_delta(0.0, methods[1].self_time, 0.01)

  assert_equal("Object#find_primes", methods[2].full_name)
  assert_equal("Integer#upto", methods[3].full_name)
  assert_equal("Array#select", methods[4].full_name)
  assert_equal("Object#is_prime", methods[5].full_name)
  assert_equal("Object#make_random_array", methods[6].full_name)
  assert_equal("Array#each_index", methods[7].full_name)
  assert_equal("Object#find_largest", methods[8].full_name)
end
