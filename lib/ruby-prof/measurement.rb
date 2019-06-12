module RubyProf
  class Measurement
    def to_s
      "c: #{called}, tt: #{total_time}, st: #{self_time}"
    end

    def inspect
      super + "(#{self.to_s})"
    end
  end
end
