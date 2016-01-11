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
  end
end
