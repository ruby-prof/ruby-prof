# encoding: utf-8

module RubyProf
  # The CallInfo class is used to track the relationships between methods. It is a helper class used by
  # RubyProf::MethodInfo to keep track of which methods called a given method and which methods a given
  # method called. Each CallInfo has a parent and target method. You cannot create a CallInfo object directly,
  # they are generated while running a profile.
  class CallInfo
    # The number of times the parent method called the target method
    def called
      self.measurement.called
    end

    # The total time resulting from the parent method calling the target method
    def total_time
      self.measurement.total_time
    end

    # The self time (of the parent) resulting from the parent method calling the target method
    def self_time
      self.measurement.self_time
    end

    # The wait time (of the parent) resulting from the parent method calling the target method
    def wait_time
      self.measurement.wait_time
    end

    # The time spent in child methods resulting from the parent method calling the target method
    def children_time
      self.total_time - self.self_time - self.wait_time
    end

    # Compares two CallInfo instances. The comparison is based on the CallInfo#parent, CallInfo#target,
    # and total time.
    def <=>(other)
      if self.target == other.target && self.parent == other.parent
        0
      elsif self.total_time < other.total_time
        -1
      elsif self.total_time > other.total_time
        1
      else
        self.target.full_name <=> other.target.full_name
      end
    end

    # :nodoc:
    def to_s
      "#{parent ? parent.full_name : '<nil>'} - #{target.full_name}"
    end

    def inspect
      super + "(#{self.to_s})"
    end
  end
end
