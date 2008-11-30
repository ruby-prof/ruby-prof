module RubyProf
  class CallInfo
    def depth
      result = 0
      call_info = self.parent

      while call_info
        result += 1
        call_info = call_info.parent
      end
      result
    end

    def children_time
      children.inject(0) do |sum, call_info|
        sum += call_info.total_time
      end
    end

    def stack
      @stack ||= begin
        methods = Array.new
        call_info = self

        while call_info
          methods << call_info.target
          call_info = call_info.parent
        end
        methods.reverse
      end
    end

    def call_sequence
      @call_sequence ||= begin
        stack.map {|method| method.full_name}.join('->')
      end
    end

    def root?
      self.parent.nil?
    end

    def to_s
      "#{call_sequence}"
    end
  end
end