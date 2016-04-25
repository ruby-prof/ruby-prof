module RubyProf
  class Walker
    attr_reader :roots
    attr_reader :min_fraction

    def initialize(roots, options={})
      @roots = roots
      @options = options

      @all_time = @roots.map(&:total_time).inject(0.0, &:+)
      @min_percent = options[:min_percent] || 2
      @min_self_percent = options[:min_self_percent] || 0.001
    end

    def run
      around_frame(@roots, :all, "all", 1, 0.0, @all_time) do
        @roots.each { |r| visit(r) }
      end
    end

    def enter_frame(type, obj, name, called, elf_value, total_value)
      raise NotImplementedError
    end

    def leave_frame(type, obj)
      raise NotImplementedError
    end

    private

    def visit(obj)
      case obj
      when RubyProf::Thread   then visit_thread(obj)
      when RubyProf::CallInfo then visit_context(obj)
      else raise ArgumentError
      end
    end

    def visit_thread(th)
      name = !th.main? ? "Thread ##{th.index}" : "Main Thread"
      around_frame(th, :thread, name, 1, 0.0, th.total_time) do
        th.top_call_infos.each { |ci| visit_context(ci) }
      end
    end

    def visit_context(ci)
      ctx_stack = []; ctx = ci
      vis_stack = []; vis = true
      idx_stack = []; idx = 0

      # Enter the current node.
      name = ctx.target.source_name
      enter_frame(:context, ctx, name, ctx.called, ctx.self_time, ctx.total_time)

      # While we still have a call info...
      while ctx
        # Does this current node has a child at this index.
        if (child = ctx.children[idx])
          # Consume the child at the next index.
          idx += 1

          total_percent = 100.0 * child.total_time / @all_time.to_f
          self_percent  = 100.0 * child.self_time / ctx.total_time.to_f
          # Does this meet the minimum requirement to explore?
          next if total_percent <= @min_percent
          # Does this span not contain enough information to be useful itself?
          hide_vis = self_percent <= @min_self_percent
          # Push the parent onto the stack.
          # The child becomes the current node.
          ctx_stack << ctx; ctx = child
          vis_stack << vis; vis = !hide_vis
          idx_stack << idx; idx = 0
          # If visualizing the span, enter it.
          if vis
            name = ctx.target.source_name
            enter_frame(:context, ctx, name, ctx.called, ctx.self_time, ctx.total_time)
          end
        else
          # If we visualized this span, leave it.
          leave_frame(:context, ctx) if vis
          # Pop the parent from the stack.
          ctx = ctx_stack.pop
          vis = vis_stack.pop
          idx = idx_stack.pop
        end
      end
    end

    def around_frame(type, obj, name, called, self_value, total_value)
      enter_frame(type, obj, name, called, self_value, total_value)
      yield
      leave_frame(type, obj)
    end
  end
end
