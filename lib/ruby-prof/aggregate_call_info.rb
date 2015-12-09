# encoding: utf-8

module RubyProf
  class AggregateCallInfo
    attr_reader :call_infos, :method_info

    def initialize(call_infos, method_info)
      if call_infos.length == 0
        raise(ArgumentError, "Must specify at least one call info.")
      end
      @call_infos = call_infos
      @method_info = method_info
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
      aggregate_roots(:total_time)
    end

    def self_time
      aggregate_roots(:self_time)
    end

    def wait_time
      aggregate_roots(:wait_time)
    end

    def children_time
      aggregate_roots(:children_time)
    end

    def called
      aggregate_all(:called)
    end

    def to_s
      "#{call_infos.first.target.full_name}"
    end

    private

    # return all call_infos which are not (grand) children of any other node in the list of given call_infos
    def roots
      @roots ||= method_info.recursive? ? CallInfo.roots_of(call_infos) : call_infos
    end

    def aggregate_all(method_name)
      call_infos.inject(0) do |sum, call_info|
        sum + call_info.send(method_name)
      end
    end

    def aggregate_roots(method_name)
      roots.inject(0) do |sum, call_info|
        sum + call_info.send(method_name)
      end
    end
  end
end
