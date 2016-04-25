# encoding: utf-8

module RubyProf
  class FlameGraphJsonPrinter < AbstractPrinter
    def min_percent
      @options[:min_percent] || 0.25
    end

    def min_self_time
      @options[:min_self_time] || 0.001
    end

    def only_threads
      @options[:only_threads]
    end

    def print_threads
      @threads = @result.threads.dup
      @threads.select! { |t| only_thread_ids.include?(t.id) } if only_threads

      walker = FlameDataWalker.new(@output, @threads, {
        min_percent: min_percent,
        min_self_time: min_self_time
      })

      @output << "{\n"
      @output << "  \"root\": "

      walker.run

      @output << ",\n"
      @output << "  \"depth\": #{walker.height}\n"
      @output << "}"
    end

    private

    def only_thread_ids
      only_threads && only_threads.map(&:object_id)
    end

    class FlameDataWalker < RubyProf::Walker
      attr_reader :output
      attr_reader :height

      def initialize(output, threads, options={})
        super(threads, options)
        @output = output

        @printer = FlameDataJsonPrinter.new(@output, {
          depth: 1,
          anchored: false
        })

        @height = 0
        @depth = 0
      end

      def enter_frame(type, obj, name, called, self_value, total_value)
        @depth += 1
        @height = @depth if @height < @depth
        @printer.enter(name, called, self_value, total_value)
      end

      def leave_frame(type, obj)
        @printer.leave
        @depth -= 1
      end
    end

    class FlameDataJsonPrinter
      attr_reader :output

      def initialize(output, options={})
        @output = output
        @depth = options[:depth] || 0
        @anchored = options.fetch(:anchored, false)
        @pretty = options.fetch(:pretty, false)
        @state = :root
        update_layout
      end

      def enter(name, called, self_value, total_value)
        case @state
        when :enter
          put_line ","
          put_part "\"children\": ["
          step_in(:enter)
        when :leave
          put_part ", "
        end

        put_line "{"
        step_in(:enter)
        put_line "\"name\": \"#{name}\","
        put_line "\"called\": #{called},"
        put_line "\"lost\": #{self_value},"
        put_part "\"value\": #{total_value}"
      end

      def leave
        case @state
        when :enter
          new_line
        when :leave
          step_out(:leave)
          put_line "]"
        end

        step_out(:leave)
        put_part "}"
      end

      private

      def put_part(str)
        @output << @indent if @anchored
        @output << str
        @anchored = false
      end

      def put_line(str)
        @output << @indent if @anchored
        @output << str
        @output << @break
        @anchored = true
      end

      def new_line
        @output << @break if !@anchored
        @anchored = true
      end

      def step_in(new_state)
        @state = new_state
        @depth += 1
        update_layout
      end

      def step_out(new_state)
        @state = new_state
        @depth -=1
        update_layout
      end

      def update_layout
        if @pretty
          @break = "\n"
          @indent = ""
        else
          @break = " "
          @indent = ""
        end
      end
    end
  end
end
