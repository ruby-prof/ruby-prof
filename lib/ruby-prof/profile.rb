# encoding: utf-8

require 'ruby-prof/exclude_common_methods'

module RubyProf
  class Profile
    # :nodoc:
    def measure_mode_string
      case self.measure_mode
        when WALL_TIME    then "wall_time"
        when PROCESS_TIME then "process_time"
        when ALLOCATIONS  then "allocations"
        when MEMORY       then "memory"
      end
    end

    # Hides methods that, when represented as a call graph, have
    # extremely large in and out degrees and make navigation impossible.
    def exclude_common_methods!
      ExcludeCommonMethods.apply!(self)
    end

    def exclude_methods!(mod, *method_or_methods)
      Array(method_or_methods).each do |name|
        exclude_method!(mod, name)
      end
    end

    def exclude_singleton_methods!(mod, *method_or_methods)
      exclude_methods!(mod.singleton_class, *method_or_methods)
    end
  end
end
