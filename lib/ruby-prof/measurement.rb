module RubyProf
  # The Measurement class is a helper class used by RubyProf::MethodInfo to store information about the method.
  # You cannot create a CallInfo object directly, they are generated while running a profile.
  class Measurement
    # :nodoc:
    def to_s
      "c: #{called}, tt: #{total_time}, st: #{self_time}"
    end

    def inspect
      super + "(#{self.to_s})"
    end
  end
end
