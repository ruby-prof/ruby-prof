module RubyProf
  # The Measurement class is used to track the relationships between methods. It is a helper class used by
  # RubyProf::MethodInfo to keep track of which methods called a given method and which methods a given
  # method called. Each CallInfo has a parent and target method. You cannot create a CallInfo object directly,
  # they are generated while running a profile.
  class Measurement
    def to_s
      "c: #{called}, tt: #{total_time}, st: #{self_time}"
    end

    def inspect
      super + "(#{self.to_s})"
    end
  end
end
