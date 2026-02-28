module RubyProf
  # The call info visitor class does a depth-first traversal across a
  # list of call infos. At each call_tree node, the visitor executes
  # the block provided in the #visit method. The block is passed two
  # parameters, the event and the call_tree instance. Event will be
  # either :enter or :exit.
  #
  #   visitor = RubyProf::CallTreeVisitor.new(result.threads.first.call_tree)
  #
  #   method_names = Array.new
  #
  #   visitor.visit do |call_tree, event|
  #     method_names << call_tree.target.full_name if event == :enter
  #   end
  #
  #   puts method_names
  class CallTreeVisitor
    def initialize(call_tree, max_depth: nil)
      @call_tree = call_tree
      @max_depth = max_depth
    end

    def visit(&block)
      visit_call_tree(@call_tree, 0, &block)
    end

    private

    def visit_call_tree(call_tree, depth, &block)
      yield call_tree, :enter
      if @max_depth.nil? || depth < @max_depth
        call_tree.children.each do |child|
          visit_call_tree(child, depth + 1, &block)
        end
      end
      yield call_tree, :exit
    end
  end
end
