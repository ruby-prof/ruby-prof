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

## Flat Report (RubyProf::FlatPrinter)

The flat report shows the overall time spent in each method. It is a good way of quickly identifying which methods take the most time.

## Graph Reports (RubyProf::GraphPrinter)

The graph report shows the overall time spent in each method. In addition, it also shows which methods call the current method and which methods it calls. Thus they are good for understanding how methods get called and provide insight into the flow of your program.

## HTML Graph Reports (RubyProf::GraphHtmlPrinter)

HTML Graph profiles are the same as graph reports, except output is generated in hyper-linked HTML. Since graph reports can be quite large, the embedded links make it much easier to navigate the results.

## Call Stack Reports (RubyProf::CallStackPrinter)

Call stack reports produce a HTML visualization of the time spent in each execution path of the profiled code.

## Call Tree (RubyProf::CallTreePrinter)

Call tree output results in the calltree profile format which is used by [KCachegrind](https://kcachegrind.github.io/html/Home.html). More information about the format can be found at the KCachegrind site.

## Graphviz Reports (RubyProf::DotPrinter)

The graphviz report is designed to be opened by [Graphviz](https://www.graphviz.org/) to create visualization of profile results.

## Call Info Reports (RubyProf::CallInfoPrinter)

Call info reports print the call tree with timing information for each node. This is mainly useful for debugging purposes as it provides access into ruby-prof's internals.

## Multiple Reports (RubyProf::MultiPrinter)

MultiPrinter can generate several reports in one profiling run. `MultiPrinter` requires a directory path and a profile basename for the files they produce:

```ruby
printer = RubyProf::MultiPrinter.new(result)
printer.print(:path => ".", :profile => "profile")
```
