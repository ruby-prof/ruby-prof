module RubyProf
  class Thread
    def top_methods
      self.methods.select do |method_info|
        method_info.call_infos.detect do |call_info|
          call_info.parent.nil?
        end
      end
    end

    def top_call_infos
      top_methods.map(&:call_infos).flatten
    end

    # This method detect recursive calls in the call tree of a given thread
    def detect_recursion
      CallInfoVisitor.detect_recursion(top_call_infos)
    end

    def total_time
      self.top_methods.inject(0) do |sum, method_info|
        method_info.call_infos.each do |call_info|
          if call_info.parent.nil?
            sum += call_info.total_time
          end
        end
        sum
      end
    end
  end
end
