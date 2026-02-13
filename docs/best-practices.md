# Best Practices

Profiling gives you amazing insight into your program. What you think is slow is almost never what is actually slow. Below are some best practices to help unlock this power.

## Start With Realistic Runs

When profiling data-heavy work, start with a smaller sample of the data instead of the full dataset. Profile a portion first (for example 1% or 10%). It is faster, easier to understand, and often enough to find the main bottleneck. Once you have a likely fix, validate it with a larger and more realistic workload so you know the result still holds in context. Run the same profile more than once and warm up before you measure so one-time startup work does not dominate the report.

## Choose The Right Measurement Mode

Pick the measurement mode based on the question you are asking. Use `WALL_TIME` for end-to-end latency, `PROCESS_TIME` for CPU-focused work, and `ALLOCATIONS` when object churn is the concern. See [Measurement Mode](advanced-usage.md#measurement-mode) for details.

## Reduce Noise Before Deep Analysis

When framework internals or concurrency noise dominate output, narrow the scope first. Use `exclude_common` or explicit method exclusions, and use thread filtering (`include_threads` / `exclude_threads`) when needed. For highly concurrent workloads, merging worker results (`merge!` or Rack `merge_fibers: true`) can make trends much easier to read. See [Profiling Options](advanced-usage.md#profiling-options), [Method Exclusion](advanced-usage.md#method-exclusion), and [Merging Threads and Fibers](advanced-usage.md#merging-threads-and-fibers).

## Use Reports In A Sequence

Start with a quick summary, then drill down. In practice, this usually means using `FlatPrinter` to find hotspots, `GraphHtmlPrinter` (or `GraphPrinter`) to understand caller/callee relationships, and `FlameGraphPrinter` to validate dominant paths visually. See [Reports](reports.md), especially [Creating Reports](reports.md#creating-reports) and [Report Types](reports.md#report-types).

## Use Threshold Filters Early

Threshold filters are one of the fastest ways to make a large profile readable. Start with `min_percent` to hide low-impact methods in most printers. For `GraphHtmlPrinter`, use `min_time` when you want to drop methods below an absolute time cutoff. These filters help you focus on the code that actually moves total runtime.

## Compare Trends, Not Single Snapshots

Do not optimize based on one run unless the signal is overwhelming. Compare before/after profiles under the same workload, then prioritize repeated hot paths over one-off spikes.
