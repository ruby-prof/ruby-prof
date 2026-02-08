# Reports

Once you have completed a profiling run, ruby-prof provides a number of reports that you can use to analyze the results. Reports are created via the use of printers:

```ruby
profile = RubyProf::Profile.profile do
            ...
          end
printer = RubyProf::GraphPrinter.new(profile)
printer.print(STDOUT, :min_percent => 2)
```

The first parameter is any writable IO object such as `STDOUT` or a file. The second parameter specifies the minimum percentage a method must take to be printed. Percentages should be specified as integers in the range 0 to 100. For more information please see the documentation for the different printers.

The different types of reports, and their associated printers, are:

## Flat Report

The flat report shows the overall time spent in each method. It is a good way of quickly identifying which methods take the most time. Use `RubyProf::FlatPrinter` to generate this report. ([example](../public/examples/reports/flat.txt))

## Graph Report

The graph report shows the overall time spent in each method. In addition, it also shows which methods call the current method and which methods it calls. Thus they are good for understanding how methods get called and provide insight into the flow of your program. Use `RubyProf::GraphPrinter` to generate this report. ([example](../public/examples/reports/graph.txt))

## HTML Graph Report

HTML Graph profiles are the same as graph reports, except output is generated in hyper-linked HTML. Since graph reports can be quite large, the embedded links make it much easier to navigate the results. Use `RubyProf::GraphHtmlPrinter` to generate this report. ([example](../public/examples/reports/graph.html))

## Call Stack Report

Call stack reports produce a HTML visualization of the time spent in each execution path of the profiled code. Use `RubyProf::CallStackPrinter` to generate this report. ([example](../public/examples/reports/call_stack.html))

## Flame Graph

Flame graph reports produce a self-contained HTML visualization of the profiled code. Each method is represented as a horizontal bar whose width is proportional to its total time. Bars are stacked vertically by call depth, making it easy to identify hot code paths at a glance. A toggle switches between flame (bottom-up) and icicle (top-down) views. Use `RubyProf::FlameGraphPrinter` to generate this report. ([example](../public/examples/reports/flame_graph.html))

Interactive features include hover tooltips (showing method name, self time, total time, percentage, and call count), click-to-zoom into a subtree, a reset zoom button, a search box to highlight matching methods, and a thread selector when multiple threads are profiled.

```ruby
printer = RubyProf::FlameGraphPrinter.new(result)
printer.print(File.open("flame_graph.html", "w"))
```

## Call Tree

Call tree output results in the calltree profile format which is used by [KCachegrind](https://kcachegrind.github.io/html/Home.html). More information about the format can be found at the KCachegrind site. Use `RubyProf::CallTreePrinter` to generate this report. ([example](../public/examples/reports/callgrind.out))

## Graphviz Report

The graphviz report is designed to be opened by [Graphviz](https://www.graphviz.org/) to create visualization of profile results. The output can be visualized using the [Graphviz Online](https://dreampuf.github.io/GraphvizOnline/) viewer. Use `RubyProf::DotPrinter` to generate this report. ([example](../public/examples/reports/graph.dot), [view online](../public/examples/reports/graphviz_viewer.html))

## Call Info Report

Call info reports print the call tree with timing information for each node. This is mainly useful for debugging purposes as it provides access into ruby-prof's internals. Use `RubyProf::CallInfoPrinter` to generate this report. ([example](../public/examples/reports/call_info.txt))

## Multiple Reports

`RubyProf::MultiPrinter` can generate several reports in one profiling run. It requires a directory path and a profile basename for the files it produces:

```ruby
printer = RubyProf::MultiPrinter.new(result)
printer.print(:path => ".", :profile => "profile")
```

## Generating Examples

To regenerate the example reports:

```
ruby docs/public/examples/generate_reports.rb
```

This profiles a small word-frequency workload and writes reports to `docs/public/examples/reports/`.
