# ruby-prof

- [Getting Started](getting-started.md) - Command line, convenience API, core API
- [Advanced Usage](advanced-usage.md) - Measurement modes, allocation tracking, thread filtering, method exclusion
- [Reports](reports.md) - Flat, graph, HTML, call stack, call tree, graphviz
- [Profiling Rails](profiling-rails.md) - Using ruby-prof with Rails applications
- [Architecture](architecture.md) - How ruby-prof works internally

## Overview

ruby-prof is a profiler for MRI Ruby. Its features include:

- Speed - it is a C extension and therefore many times faster than the standard Ruby profiler.
- Measurement Modes - ruby-prof can measure program wall time, process time and object allocations.
- Reports - ruby-prof can generate a variety of text and cross-referenced html reports.
- Threads - supports profiling multiple threads simultaneously.

## Why ruby-prof?

ruby-prof is helpful if your program is slow and you don't know why. It can help you track down methods that are either slow, allocate a large number of objects or allocate objects with high memory usage. Often times the results will be surprising - when profiling what you think you know almost always turns out to be wrong.

Since ruby-prof is built using ruby's C [tracepoint](https://ruby-doc.org/core-2.6.1/TracePoint.html) api, it knows a lot about your program. However, using ruby-prof also comes with two caveats:

- To use ruby-prof you generally need to include a few lines of extra code in your program (although see [command line usage](getting-started.md#command-line))
- Using ruby-prof will cause your program to run slower (see [Performance](#performance) section)

Most of the time, these two caveats are acceptable. But if you need to determine why a program running in production is slow or hung, a sampling profiler will be a better choice. Excellent choices include [stackprof](https://github.com/tmm1/stackprof) or [rbspy](https://rbspy.github.io/).

If you are just interested in memory usage, you may also want to checkout the [memory_profiler](https://github.com/SamSaffron/memory_profiler) gem (although ruby-prof provides similar information).

## Installation

The easiest way to install ruby-prof is by using Ruby Gems. To install:

```
gem install ruby-prof
```

If you are running Linux or Unix you'll need to have a C compiler installed so the extension can be built when it is installed. If you are running Windows, then you should install the Windows specific gem or install [devkit](https://rubyinstaller.org/add-ons/devkit.html).

ruby-prof requires Ruby 3.0.0 or higher.

## Performance

Significant effort has been put into reducing ruby-prof's overhead. Our tests show that the overhead associated with profiling code varies considerably with the code being profiled. Most programs will run approximately twice as slow while highly recursive programs (like the fibonacci series test) will run up to five times slower.

## Version History

For a full list of changes between versions, see the [CHANGES](../CHANGES) file.

Notable milestones:

- **1.0** - Major rewrite with significantly faster profiling, correct recursive profile handling, redesigned reports, allocation/memory measurement without patched Ruby, and save/reload of profiling results.
- **1.7** - Dropped Ruby 2.7 support, added Ruby 3.3 support.
- **1.8** - Ruby 4.0 support. Removed `RubyProf::MEMORY` measurement mode (no longer works on Ruby 4.0).

## API Documentation

API documentation for each class is available at the [ruby-prof API docs](https://ruby-prof.github.io/doc/index.html).

## License

See [LICENSE](../LICENSE) for license information.

## Development

Code is located at [github.com/ruby-prof/ruby-prof](https://github.com/ruby-prof/ruby-prof).
