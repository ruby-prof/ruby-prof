# encoding: utf-8

require 'ruby-prof/exclude_common_methods'

module RubyProf
  class Profile
    # :nodoc:
    def measure_mode_string
      case self.measure_mode
        when WALL_TIME
          "wall_time"
        when PROCESS_TIME
          "process_time"
        when ALLOCATIONS
          "allocations"
        when MEMORY
          "memory"
      end
    end

    # Hides methods that, when represented as a call graph, have
    # extremely large in and out degrees and make navigation impossible.
    def exclude_common_methods!
      ExcludeCommonMethods.apply!(self)
    end

    def exclude_methods!(mod, *method_or_methods)
      [method_or_methods].flatten.each do |name|
        exclude_method!(mod, name)
      end
    end

    def exclude_singleton_methods!(mod, *method_or_methods)
      exclude_methods!(mod.singleton_class, *method_or_methods)
    end

    def exclude_module!(mod)
      exclude_methods!(mod, mod.methods + mod.instance_methods)
    end

    def exclude_methods_by_pattern!(pattern)
      separator = '\\' + pattern[/[#.]/]

      return exclude_module!(Object.const_get(pattern)) unless separator

      mod, methods_pattern = pattern.split(/#{separator}/, 2)
                                    .each_slice(2).map do |mod, pat|
                                       [Object.const_get(mod), Regexp.new(pat)]
                                     end.flatten


      method_or_methods = if separator == '#'
                            mod.instance_methods.grep(methods_pattern)
                          else
                            mod.methods.grep(methods_pattern)
                          end

      mod = separator == '#' ? mod : mod.singleton_class

      exclude_methods!(mod, method_or_methods)
    end
  end
end
