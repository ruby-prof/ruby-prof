# encoding: utf-8

module RubyProf
  class MethodInfo
    include Comparable

    def full_name
      decorated_class_name = case self.klass_flags
                             when 0x2
                               "<Class::#{klass_name}>"
                             when 0x4
                               "<Module::#{klass_name}>"
                             when 0x8
                               "<Object::#{klass_name}>"
                             else
                               klass_name
                             end

      "#{decorated_class_name}##{method_name}"
    end

    def <=>(other)
      if self.total_time < other.total_time
        -1
      elsif self.total_time > other.total_time
        1
      elsif self.min_depth < other.min_depth
        1
      elsif self.min_depth > other.min_depth
        -1
      else
        self.full_name <=> other.full_name
      end
    end

    def recursive?
      self.callers.detect(&:recursive?)
    end

    def called
      @called ||= begin
        callers.inject(0) do |sum, call_info|
          sum + call_info.called
        end
      end
    end

    def total_time
      @total_time ||= begin
        callers.inject(0) do |sum, call_info|
          sum += call_info.total_time if !call_info.recursive?
          sum
        end
      end
    end

    def children_time
      @children_time ||= begin
        callers.inject(0) do |sum, call_info|
          sum += call_info.children_time if !call_info.recursive?
          sum
        end
      end
    end

    def wait_time
      @wait_time ||= begin
        callers.inject(0) do |sum, call_info|
          sum += call_info.wait_time if !call_info.recursive?
          sum
        end
      end
    end

    def self_time
      @self_time ||= begin
        callers.inject(0) do |sum, call_info|
          sum += call_info.self_time if !call_info.recursive?
          sum
        end
      end
    end

    def min_depth
      @min_depth ||= callers.map(&:depth).min
    end

    # def aggregate_parents
    #   # group call infos based on their parents
    #   groups = self.callers.each_with_object({}) do |call_info, hash|
    #     key = call_info.parent ? call_info.parent.target : self
    #     (hash[key] ||= []) << call_info
    #   end
    #
    #   groups.map do |key, value|
    #     AggregateCallInfo.new(value, self)
    #   end
    # end
    #
    # def aggregate_children
    #   # group call infos based on their targets
    #   groups = self.children.each_with_object({}) do |call_info, hash|
    #     key = call_info.target
    #     (hash[key] ||= []) << call_info
    #   end
    #
    #   groups.map do |key, value|
    #     AggregateCallInfo.new(value, self)
    #   end
    # end

    def to_s
      "#{self.full_name} (c: #{self.called}, tt: #{self.total_time}, st: #{self.self_time}, wt: #{wait_time}, ct: #{self.children_time})"
    end

    # remove method from the call graph. should not be called directly.
    def eliminate!
      # $stderr.puts "eliminating #{self}"
      callers.each{ |call_info| call_info.eliminate! }
      callers.clear
    end
  end
end
