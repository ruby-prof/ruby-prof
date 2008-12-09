module RubyProf
  class AggregateCallInfo
    attr_reader :call_infos
    def initialize(call_infos)
      if call_infos.length == 0
        raise(ArgumentError, "Must specify at least one call info.")
      end
      @call_infos = call_infos
    end

    def target
      call_infos.first.target
    end

    def parent
      call_infos.first.parent
    end

    def line
      call_infos.first.line
    end

    def children
      call_infos.inject(Array.new) do |result, call_info|
        result.concat(call_info.children)
      end
    end

    def total_time
      aggregate(:total_time)
    end

    def self_time
      aggregate(:self_time)
    end

    def wait_time
      aggregate(:wait_time)
    end

    def children_time
      aggregate(:children_time)
    end

    def called
      aggregate(:called)
    end

    def to_s
      "#{call_infos.first.full_name}"
    end

    private

    def aggregate(method_name)
      self.call_infos.inject(0) do |sum, call_info|
        sum += call_info.send(method_name)
        sum
      end
    end
  end
end