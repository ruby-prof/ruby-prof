module RubyProf
  class Thread
    # Returns the root methods (ie, methods that were not called by other methods) that were profiled while
    # this thread was executing. Generally there is only one root method (multiple root methods can occur
    # when Profile#pause is used). By starting with the root methods, you can descend down the profile
    # call tree.
    def root_methods
      self.methods.select do |method_info|
        method_info.root?
      end
    end

    # Returns the total time this thread was executed.
    def total_time
      self.root_methods.inject(0) do |sum, method_info|
        method_info.callers.each do |call_info|
          sum += call_info.total_time
        end
        sum
      end
    end

    # Returns the amount of time this thread waited while other thread executed.
    def wait_time
      # wait_time, like self:time, is always method local
      # thus we need to sum over all methods and call infos
      self.methods.inject(0) do |sum, method_info|
        method_info.callers.each do |call_info|
          sum += call_info.wait_time
        end
        sum
      end
    end
  end
end
