# The call info visitor class does a depth-first traversal
# across a thread's call stack.  At each call_info node,
# the visitor executes the block provided in the
# #visit method.  The block is passed two parameters, the
# event and the call_info instance.  Event will be
# either :enter or :exit.
#
#   visitor = RubyProf::CallInfoVisitor.new(result.threads.first)
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

    def initialize(thread)
      @thread = thread
    end

    def visit(&block)
      @thread.top_methods.each do |method_info|
        method_info.call_infos.each do |call_info|
          visit_call_info(call_info, &block)
        end
      end
    end

    private
    
    def visit_call_info(top_call_info, &block)
      # Keeps track of the child index, so we can get the next child quickly.
      stack = [0]
      
      # The current depth of the tree, stack[depth] the current child index.
      depth = 0
      
      # The current location in the tree.
      current = top_call_info
      
      yield current, :enter
      
      # While we have a valid tree:
      while current
        # Fetch the child index for this node:
        index = stack[depth]
        
        # If there is a valid child for this index:
        if index < current.children.size
          # Move to this child:
          current = current.children[index]
          
          # Visit the current node:
          yield current, :enter
          
          # Update the next child index:
          stack[depth] += 1
          
          # Increase in depth:
          depth += 1
          
          # Since we haven't visited any children yet, set the child index to 0:
          stack[depth] = 0
        else
          # Otherwise, move back up the tree:
          yield current, :exit
          
          # Sometimes top_call_info.parent doesn't seem to be nil?
          break if depth == 0
          
          current = current.parent
          depth -= 1
        end
      end
    end
  end
end
