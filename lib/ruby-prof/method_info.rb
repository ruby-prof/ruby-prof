# encoding: utf-8

module RubyProf
  # The MethodInfo class is used to track information about each method that is profiled.
  # You cannot create a MethodInfo object directly, they are generated while running a profile.
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
      if other == nil
        -1
      elsif self.full_name == other.full_name
        0
      elsif self.total_time < other.total_time
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

    def called
      self.measurement.called
    end

    def total_time
      self.measurement.total_time
    end

    def self_time
      self.measurement.self_time
    end

    def wait_time
      self.measurement.wait_time
    end

    def children_time
      self.total_time - self.self_time - self.wait_time
    end

    def min_depth
      @min_depth ||= callers.map(&:depth).min
    end

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
