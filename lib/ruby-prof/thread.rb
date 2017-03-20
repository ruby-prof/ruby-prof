module RubyProf
  class Thread
    def top_methods
      self.methods.select(&:root?)
    end

    def top_call_infos
      top_methods.flat_map(&:call_infos).keep_if(&:root?)
    end

    # This method detect recursive calls in the call tree of a given thread
    # It should be called only once for each thread
    def detect_recursion
      top_call_infos.each(&:detect_recursion)
    end

    def total_time
      @total_time = self.top_call_infos.inject(0) do |sum, call_info|
        sum += call_info.total_time
      end
    end

    def wait_time
      # wait_time, like self:time, is always method local
      # thus we need to sum over all methods and call infos
      self.methods.inject(0) do |sum, method_info|
        method_info.call_infos.each do |call_info|
          sum += call_info.wait_time
        end
        sum
      end
    end
  end
end
