# History

For a full list of changes between versions, see the [Changelog](changelog.md).

The first version of ruby-prof, 0.1.1, was released on March 22, 2005 by [Shugo Maeda](https://shugo.net/) The original [source](https://shugo.net/archive/ruby-prof/) code is still available on his website (it is not actually in the git history). ruby-prof was a vast improvement at the time, running 30 times faster as the original ruby profiler.

Version [0.4.0](https://rubygems.org/gems/ruby-prof/versions/0.4.0) was the first version packaged as a Ruby gem. Version 0.4.0 also introduced Windows support, thread support and added a number of additional reports such as the graph report in HTML and the call graph report.

A number of versions were subsequently released, with a 1.0.0 [release](https://cfis.savagexi.com/2019/07/29/ruby-prof-1-0/) finally happening in July of 2019. Version 1.0.0 was a major rewrite that significantly improved performance, correctly profiled recursive methods, redesigned reports, added allocation/memory measurement support and introduced saving and reloading profiling results. Since then ruby-prof has continued to evolve along with Ruby with 19 releases.

Version 2.0.0 will mark the 20th release of ruby-prof since the 1.0.0 release. Version 2.0.0 supports Ruby 4 and includes new flame/icicle graph support, revamped reports and improved documentation. The reason for the 2.0.0 jump is because profiling memory sizes has been removed due to changes in Ruby 4.0.0. In addition, the old compatibility API was also removed.
