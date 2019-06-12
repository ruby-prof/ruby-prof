# encoding: utf-8

module RubyProf
  class CallInfo
    # part of this class is defined in C code.
    # it provides the following attributes pertaining to tree structure:
    # depth:      tree level (0 == root)
    # parent:     parent call info (can be nil)
    # target:     method info (containing an array of call infos)

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

    def to_s
      "#{parent ? parent.full_name : '<nil>'} - #{target.full_name}"
    end

    def inspect
      super + "(#{self.to_s})"
    end

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

    # find a specific call in list of children. returns nil if not found.
    # note: there can't be more than one child with a given target method. in other words:
    # x.children.grep{|y|y.target==m}.size <= 1 for all method infos m and call infos x
    def find_call(other)
      matching = children.select { |kid| kid.target == other.target }
      raise "inconsistent call tree" unless matching.size <= 1
      matching.first
    end
  end
end
