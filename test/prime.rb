# A silly little test program that finds prime numbers.  It
# is intentionally badly designed to show off the use
# of ruby-prof.
#
# Source from http://people.cs.uchicago.edu/~bomb154/154/maclabs/profilers-lab/

require File.expand_path('../test_helper', __FILE__)
require 'fileutils'

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

# Generate example reports - this assumes the ruby-prof.github.io project is checked out in parallel direcotry
def generate_reports(result)
  path = File.join('..', '..', 'ruby-prof.github.io', 'examples')
  path = File.expand_path(path)
  FileUtils.makedirs(path)
  printer = RubyProf::MultiPrinter.new(result, [:flat, :flat_with_lines, :graph, :graph_html, :call_info, :tree, :stack, :dot])
  printer.print(:path => path, :profile => 'primes')
end

def run
  start = Process.times
  result = RubyProf.profile do
    run_primes(10000)
  end

  generate_reports(result)
end

run
