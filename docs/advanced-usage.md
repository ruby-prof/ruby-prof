# Advanced Usage

This section describes advanced usage of ruby-prof. Additional documentation for every class is also [available](index.md#api-documentation).

## Profiling Options

ruby-prof understands the following options when profiling code:

**measure_mode** - What ruby-prof should measure. For more information see the [Measurement Mode](#measurement-mode) section.

**track_allocations** - Tracks each object location, including the object class, memory size and source file location. For more information see the [Allocation Tracking](#allocation-tracking) section.

**exclude_threads** - Array of threads which should not be profiled. For more information see the [Thread Inclusion/Exclusion](#thread-inclusionexclusion) section.

**include_threads** - Array of threads which should be profiled. All other threads will be ignored. For more information see the [Thread Inclusion/Exclusion](#thread-inclusionexclusion) section.

**allow_exceptions** - Whether to raise exceptions encountered during profiling, or to suppress them. Defaults to false.

**exclude_common** - Automatically calls `exclude_common_methods!` to exclude commonly cluttering methods. Defaults to false. For more information see the [Method Exclusion](#method-exclusion) section.

## Measurement Mode

The measurement mode determines what ruby-prof measures when profiling code. Supported measurements are:

### Wall Time

Wall time measures the real-world time elapsed between any two moments in seconds. If there are other processes concurrently running on the system that use significant CPU or disk time during a profiling run then the reported results will be larger than expected. On Windows, wall time is measured using `QueryPerformanceCounter` and on other platforms by `clock_gettime(CLOCK_MONOTONIC)`. Use `RubyProf::WALL_TIME` to select this mode.

### Process Time

Process time measures the time used by a process between any two moments in seconds. It is unaffected by other processes concurrently running on the system. Remember with process time that calls to methods like sleep will not be included in profiling results. On Windows, process time is measured using `GetProcessTimes` and on other platforms by `clock_gettime`. Use `RubyProf::PROCESS_TIME` to select this mode.

### Object Allocations

Object allocations measures how many objects each method in a program allocates. Measurements are done via Ruby's `RUBY_INTERNAL_EVENT_NEWOBJ` trace event, counting each new object created (excluding internal `T_IMEMO` objects). Use `RubyProf::ALLOCATIONS` to select this mode.

To set the measurement mode:

```ruby
profile = RubyProf::Profile.new(measure_mode: RubyProf::WALL_TIME)
profile = RubyProf::Profile.new(measure_mode: RubyProf::PROCESS_TIME)
profile = RubyProf::Profile.new(measure_mode: RubyProf::ALLOCATIONS)
```

The default value is `RubyProf::WALL_TIME`. You may also specify the measure mode by using the `RUBY_PROF_MEASURE_MODE` environment variable:

```
export RUBY_PROF_MEASURE_MODE=wall
export RUBY_PROF_MEASURE_MODE=process
export RUBY_PROF_MEASURE_MODE=allocations
```

## Allocation Tracking

ruby-prof also has the ability to track object allocations. This functionality can be turned on via the track_allocations option:

```ruby
require 'ruby-prof'

RubyProf::Profile.profile(:track_allocations => true) do
  ...
end
```

Note the `RubyProf::ALLOCATIONS` measure mode is slightly different than tracking allocations. The measurement mode provides high level information about the number of allocations performed in each method. In contrast, tracking allocations provides detailed information about the type, number, memory usage and location of each allocation. Currently, to see allocations results you must use the `RubyProf::GraphHtmlPrinter`.

## Thread Inclusion/Exclusion

ruby-prof can profile multiple threads. Sometimes this can be overwhelming. For example, assume you want to determine why your tests are running slowly. If you are using minitest, it will run your tests in parallel by spawning tens of worker threads (note to tell minitest to use a single thread set the N environmental variable like this ENV = 0). Thus, ruby-prof provides two options to specify which threads should be profiled:

**exclude_threads** - Array of threads which should not be profiled.

**include_threads** - Array of threads which should be profiled. All other threads will be ignored.

## Method Exclusion

ruby-prof supports excluding specific methods and threads from profiling results. This is useful for reducing connectivity in the call graph, making it easier to identify the source of performance problems when using a graph printer. For example, consider `Integer#times`: it's hardly ever useful to know how much time is spent in the method itself. We are more interested in how much the passed in block contributes to the time spent in the method which contains the `Integer#times` call. The effect on collected metrics are identical to eliminating methods from the profiling result in a post process step.

```ruby
profile = RubyProf::Profile.new(...)
profile.exclude_methods!(Integer, :times, ...)
profile.start
```

A convenience method is provided to exclude a large number of methods which usually clutter up profiles:

```ruby
profile.exclude_common_methods!
```

However, this is a somewhat opinionated method collection. It's usually better to view it as an inspiration instead of using it directly (see [exclude_common_methods.rb](https://github.com/ruby-prof/ruby-prof/blob/e087b7d7ca11eecf1717d95a5c5fea1e36ea3136/lib/ruby-prof/profile/exclude_common_methods.rb)).

## Merging Threads and Fibers

ruby-prof profiles each thread and fiber separately. A common design pattern is to have a main thread delegate work to background threads or fibers. Examples include web servers such as Puma and Falcon, as well as code that uses `Enumerator`, `Fiber.new`, or async libraries.

Understanding profiling results can be very difficult when there are many threads or fibers because each one appears as a separate entry in the output. To help with this, ruby-prof includes the ability to merge results for threads and fibers that start with the same root method. In the best case, this can collapse results into just two entries - one for the parent thread and one for all workers.

Note the collapsed results show the sum of times for all merged threads/fibers. For example, assume there are 10 worker fibers that each took 5 seconds to run. The single merged entry will show a total time of 50 seconds.

To merge threads and fibers:

```ruby
profile = RubyProf::Profile.profile do
            ...
          end
profile.merge!
```

This is also supported in the Rack adapter via the `merge_fibers` option:

```ruby
config.middleware.use Rack::RubyProf, :path => './tmp/profile', :merge_fibers => true
```

## Saving Results

It can be helpful to save the results of a profiling run for later analysis. Results can be saved using Ruby's [marshal](https://docs.ruby-lang.org/en/master/Marshal.html) library.

```ruby
profile_1 = RubyProf::Profile.profile do
  ...
end

# Save the results
data = Marshal.dump(profile_1)

# Sometime later load the results
profile_2 = Marshal.load(data)
```

**!!!WARNING!!!** - Only load ruby-prof profiles that you know are safe. Demarshaling data can lead to arbitrary code execution and thus can be [dangerous](https://docs.ruby-lang.org/en/master/Marshal.html#module-Marshal-label-Security+considerations).
