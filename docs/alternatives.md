# Comparison with Other Profilers

Ruby has several excellent profiling tools, each with different strengths. This page compares ruby-prof with three popular alternatives to help you choose the right tool for your needs.

## Tracing vs Sampling

The most important distinction between profilers is **tracing** vs **sampling**:

- **Tracing profilers** (ruby-prof) instrument every method call and return. This provides exact call counts and complete call graphs, but adds overhead to every method invocation.
- **Sampling profilers** (stackprof, rbspy, vernier) periodically capture stack snapshots. This has much lower overhead but may miss short-lived method calls.

## Overview

The table below compares ruby-prof with [stackprof](https://github.com/tmm1/stackprof), [rbspy](https://github.com/rbspy/rbspy), and [vernier](https://github.com/jhawthorn/vernier) — the three most popular sampling profilers for Ruby.

| | ruby-prof | stackprof | rbspy | vernier |
|---|---|---|---|---|
| **Type** | Tracing | Sampling | Sampling | Sampling |
| **Implementation** | C extension (TracePoint API) | C extension (signals) | External Rust binary | C extension (signals) |
| **Code changes** | None ([CLI](getting-started.md#command-line)) or minimal | Minimal | None | Minimal |
| **Ruby versions** | All, since 2006 (currently 3.2+) | 2.2+ | 1.9.3+ | 3.2.1+ |
| **OS support** | Linux, macOS, Windows | Linux | Linux, macOS, Windows, FreeBSD | Linux, macOS |

## Measurement Capabilities

| | ruby-prof | stackprof | rbspy | vernier |
|---|---|---|---|---|
| **Wall time** | Yes | Yes | Yes | Yes |
| **CPU/Process time** | Yes | Yes | No | No |
| **Allocations** | Yes | Yes | No | Yes |
| **GVL visibility** | No | No | No | Yes |
| **GC pauses** | No | No | No | Yes |
| **Retained memory** | No | No | No | Yes |
| **Multi-thread** | Yes | No | No | Yes |
| **Fibers** | Yes | No | No | No |

## Report Formats

| | ruby-prof | stackprof | rbspy | vernier |
|---|---|---|---|---|
| **Flat/Summary** | Yes | Yes | Yes | No |
| **Call graph** | Yes (text + HTML) | No | No | No |
| **Flame graph** | Yes (HTML) | Yes | Yes (SVG) | Yes (Firefox Profiler) |
| **Call stack** | Yes (HTML) | No | No | No |
| **Callgrind** | Yes | No | Yes | No |
| **Graphviz dot** | Yes | Yes | No | No |

## When to Use Each

### ruby-prof

ruby-prof is the longest-standing Ruby profiler, with its [first](./history.md) release in 2005. It has been continuously maintained for nearly two decades, evolving alongside Ruby itself from 1.8 through 4.0. Over that time it has supported every major Ruby version and platform, including Windows — a rarity among Ruby C extensions.

Being a tracing profiler, ruby-prof provides *exact* information about your program. It tracks every thread, every fiber and every method call. It shines with its support for multiple measurements modes and excellent reporting capabilities. 

ruby-prof can be used from the [command line](getting-started.md#command-line) with no code changes, or via an API for more control.

The biggest downsides of ruby-prof are:

* It adds significant overhead for running programs, so is not suitable for production use
* It must start a Ruby program, it cannot attach to an already running program

### stackprof

[stackprof](https://github.com/tmm1/stackprof) is a low-overhead, sampling profiler that is good for development. It adds minimal overhead while still providing useful flame graphs and per-line hit counts. A good choice when you want something lightweight and well-established.

The biggest downsides of stackprof are:

 * Single-thread only
 * Linux only for time-based modes

### rbspy

[rbspy](https://github.com/rbspy/rbspy) is a sampling profiler best for profiling in production or when you cannot modify the application code. As an external process, it attaches to a running Ruby process by PID with zero code changes. Supports the widest range of Ruby versions.

The biggest downsides of rbspy are:

* No allocation profiling
* No call graph or caller/callee data
* Since it is written in Rust, you will also need to install the Rust compiler.

### vernier

[vernier](https://github.com/jhawthorn/vernier) is a sampling profiler best for diagnosing concurrency issues and understanding GVL contention. It is the only Ruby profiler that reports GVL state, GC pauses and idle time. Its Firefox Profiler integration provides rich interactive visualizations with per-thread timelines.

The biggest downsides of rbspy are:

* Requires Ruby 3.2.1+
* No Windows support

## Memory Profiling

[memory_profiler](https://github.com/SamSaffron/memory_profiler) is another profiler, but it focuses exclusively on memory usage. It uses Ruby's `ObjectSpace` API to track every object allocation during a block of code, recording the source file, line number, object type, and size via `ObjectSpace.memsize_of`. By snapshotting the GC generation before and after, it distinguishes between allocated objects (created during the block) and retained objects (still alive after GC). This makes it useful for finding memory leaks and identifying allocation-heavy code. It's pure Ruby with no C extension, so it works across Ruby versions and platforms.

ruby-prof can track allocation counts via its `RubyProf::ALLOCATIONS` mode, but memory_profiler gives deeper insight into memory specifically — object sizes, retained vs allocated, and per-gem breakdowns.