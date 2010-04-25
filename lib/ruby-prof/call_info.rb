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

    def minimal?
      @minimal
    end

    def compute_minimality(parent_methods)
      if parent_methods.include?(target)
        @minimal = false
      else
        @minimal = true
        parent_methods << target unless children.empty?
      end
      children.each {|ci| ci.compute_minimality(parent_methods)}
      parent_methods.delete(target) if @minimal && !children.empty?
    end

    # eliminate call info from the call tree.
    # adds self and wait time to parent and attaches called methods to parent.
    # merges call trees for methods called from both praent end self.
    def eliminate!
      # puts "eliminating #{self}"
      return unless parent
      parent.add_self_time(self)
      parent.add_wait_time(self)
      children.each do |kid|
        if call = parent.find_call(kid)
          call.merge_call_tree(kid)
        else
          parent.children << kid
          # $stderr.puts "setting parent of #{kid}\nto #{parent}"
          kid.parent = parent
        end
      end
      parent.children.delete(self)
    end

    # find a sepcific call in list of children. returns nil if not found.
    # note: there can't be more than one child with a given target method. in other words:
    # x.children.grep{|y|y.target==m}.size <= 1 for all method infos m and call infos x
    def find_call(other)
      matching = children.select { |kid| kid.target == other.target }
      raise "inconsistent call tree" unless matching.size <= 1
      matching.first
    end

    # merge two call trees. adds self, wait, and total time of other to self and merges children of other into children of self.
    def merge_call_tree(other)
      # $stderr.puts "merging #{self}\nand #{other}"
      self.called += other.called
      add_self_time(other)
      add_wait_time(other)
      add_total_time(other)
      other.children.each do |other_kid|
        if kid = find_call(other_kid)
          # $stderr.puts "merging kids"
          kid.merge_call_tree(other_kid)
        else
          other_kid.parent = self
          children << other_kid
        end
      end
      other.children.clear
      other.target.call_infos.delete(other)
    end

  end
end
