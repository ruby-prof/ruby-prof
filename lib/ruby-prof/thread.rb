module RubyProf
  class Thread
    def root_methods
      self.methods.select do |method_info|
        method_info.root?
      end
    end

    # def top_call_infos
    #   root_methods.select(&:root?).map(&:callers).flatten
    # end

    def total_time
      self.root_methods.inject(0) do |sum, method_info|
        method_info.callers.each do |call_info|
          sum += call_info.total_time
        end
        sum
      end
    end

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
