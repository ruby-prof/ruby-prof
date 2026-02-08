# Getting Started

There are three ways to use ruby-prof:

- command line
- convenience API
- core API

## Command Line

The easiest way to use ruby-prof is via the command line, which requires no modifications to your program. The basic usage is:

```
ruby-prof [options] <script.rb> [--] [script-options]
```

Where script.rb is the program you want to profile.

For a full list of options, see the RubyProf::Cmd documentation or execute the following command:

```
ruby-prof -h
```

## Convenience API

The second way to use ruby-prof is via its convenience API. This requires small modifications to the program you want to profile:

```ruby
require 'ruby-prof'

profile = RubyProf::Profile.new

# profile the code
profile.start
# ... code to profile ...
result = profile.stop

# print a flat profile to text
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
```

Alternatively, you can use a block to tell ruby-prof what to profile:

```ruby
require 'ruby-prof'

# profile the code
result = RubyProf::Profile.profile do
  # ... code to profile ...
end

# print a graph profile to text
printer = RubyProf::GraphPrinter.new(result)
printer.print(STDOUT, {})
```

ruby-prof also supports pausing and resuming profiling runs.

```ruby
require 'ruby-prof'

profile = RubyProf::Profile.new

# profile the code
profile.start
# ... code to profile ...

profile.pause
# ... other code ...

profile.resume
# ... code to profile ...

result = profile.stop
```

Note that resume will only work if start has been called previously. In addition, resume can also take a block:

```ruby
require 'ruby-prof'

profile = RubyProf::Profile.new

# profile the code
profile.start
# ... code to profile ...

profile.pause
# ... other code ...

profile.resume do
  # ... code to profile...
end

result = profile.stop
```

With this usage, resume will automatically call pause at the end of the block.

The `RubyProf::Profile.profile` method can take various options, which are described in [Profiling Options](advanced-usage.md#profiling-options).

## Core API

The convenience API is a wrapper around the `RubyProf::Profile` class. Using the Profile class directly provides additional functionality, such as [method exclusion](advanced-usage.md#method-exclusion).

To create a new profile:

```ruby
require 'ruby-prof'

profile = RubyProf::Profile.new(options)
result = profile.profile do
           ...
         end
```

Once a profile is completed, you can either generate a [report](reports.md) via a printer or [save](advanced-usage.md#saving-results) the results for later analysis. For a list of profiling options, please see the [Profiling Options](advanced-usage.md#profiling-options) section.
