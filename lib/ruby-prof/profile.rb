# encoding: utf-8

require 'ruby-prof/exclude_common_methods'

module RubyProf
  class Profile
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

    def merge!
      # First group threads by their root call tree methods. If the methods are
      # different than there is nothing to merge
      grouped = threads.group_by do |thread|
        thread.call_tree.target
      end

      # For each group of threads, get the first one, merge the other threads into it, then
      # delete the other threads
      merged_threads = grouped.map do |call_tree, threads|
        thread = threads.shift
        threads.each do |other_thread|
          thread.merge!(other_thread)
          remove_thread(other_thread)
        end
        thread
      end
    end
  end
end
