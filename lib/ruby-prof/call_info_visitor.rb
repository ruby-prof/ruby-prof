# The call info visitor class does a depth-first traversal across a
# list of method infos. At each call_info node, the visitor executes
# the block provided in the #visit method. The block is passed two
# parameters, the event and the call_info instance. Event will be
# either :enter or :exit.
#
#   visitor = RubyProf::CallInfoVisitor.new(result.threads.first.top_call_infos)
#
#   method_names = Array.new
#
#   visitor.visit do |call_info, event|
#     method_names << call_info.target.full_name if event == :enter
#   end
#
#   puts method_names

module RubyProf
  class CallInfoVisitor

    def initialize(call_infos)
      @call_infos = CallInfo.roots_of(call_infos)
    end

    def visit(&block)
      @call_infos.each do |call_info|
        visit_call_info(call_info, &block)
      end
    end

    def self.detect_recursion(call_infos)
      visited_methods = Hash.new(0)
      visitor = new(call_infos)
      visitor.visit do |call_info, event|
        target = call_info.target
        target.clear_cached_values_which_depend_on_recursiveness
        case event
        when :enter
          call_info.recursive = (visited_methods[target] += 1) > 1
        when :exit
          visited_methods.delete(target) if (visited_methods[target] -= 1) == 0
        end
      end
    end

    private
    def visit_call_info(call_info, &block)
      yield call_info, :enter
      call_info.children.each do |child|
        visit_call_info(child, &block)
      end
      yield call_info, :exit
    end
  end

end
