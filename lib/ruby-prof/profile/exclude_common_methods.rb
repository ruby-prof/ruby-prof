require 'set'

module RubyProf
  class Profile
    class ExcludeCommonMethods
      ENUMERABLE_NAMES = Enumerable.instance_methods(false)

      def self.apply!(profile)
        new(profile).apply!
      end

      def initialize(profile)
        @profile = profile
      end

      def apply!
        ##
        #  Kernel Methods
        ##

        exclude_methods Kernel, [
          :dup,
          :initialize_dup,
          :tap,
          :send,
          :public_send,
        ]

        ##
        #  Fundamental Types
        ##

        exclude_methods BasicObject,  :"!="
        exclude_methods Method,       :"[]"
        exclude_methods Module,       :new
        exclude_methods Class,        :new
        exclude_methods Proc,         :call, :yield
        exclude_methods Range,        :each
        exclude_methods Integer,      :times

        ##
        #  Value Types
        ##

        exclude_methods String, [
          :sub,
          :sub!,
          :gsub,
          :gsub!,
        ]

        ##
        #  Emumerables
        ##

        exclude_enumerable Enumerable
        exclude_enumerable Enumerator

        ##
        #  Collections
        ##

        exclude_enumerable Array, [
          :each_index,
          :map!,
          :select!,
          :reject!,
          :collect!,
          :sort!,
          :sort_by!,
          :index,
          :delete_if,
          :keep_if,
          :drop_while,
          :uniq,
          :uniq!,
          :"==",
          :eql?,
          :hash,
          :to_json,
          :as_json,
          :encode_json,
        ]

        exclude_enumerable Hash, [
          :dup,
          :initialize_dup,
          :fetch,
          :"[]",
          :"[]=",
          :each_key,
          :each_value,
          :each_pair,
          :map!,
          :select!,
          :reject!,
          :collect!,
          :delete_if,
          :keep_if,
          :slice,
          :slice!,
          :except,
          :except!,
          :"==",
          :eql?,
          :hash,
          :to_json,
          :as_json,
          :encode_json,
        ]

        exclude_enumerable Set, [
          :map!,
          :select!,
          :reject!,
          :collect!,
          :classify,
          :delete_if,
          :keep_if,
          :divide,
          :"==",
          :eql?,
          :hash,
          :to_json,
          :as_json,
          :encode_json,
        ]

        ##
        #  Garbage Collection
        ##

        exclude_singleton_methods GC, [
          :start
        ]

        ##
        #  Unicorn
        ##

        if defined?(Unicorn)
          exclude_methods Unicorn::HttpServer, :process_client
        end

        if defined?(Unicorn::OobGC)
          exclude_methods Unicorn::OobGC, :process_client
        end

        ##
        #  New Relic
        ##

        if defined?(NewRelic)
          exclude_methods NewRelic::Agent::Instrumentation::MiddlewareTracing, [
            :call
          ]

          exclude_methods NewRelic::Agent::MethodTracerHelpers, [
            :trace_execution_scoped,
            :log_errors,
          ]

          exclude_singleton_methods NewRelic::Agent::MethodTracerHelpers, [
            :trace_execution_scoped,
            :log_errors,
          ]

          exclude_methods NewRelic::Agent::MethodTracer, [
            :trace_execution_scoped,
            :trace_execution_unscoped,
          ]
        end

          ##
          #  Miscellaneous Methods
          ##

        if defined?(Mustache)
          exclude_methods Mustache::Context, [
            :fetch
          ]
        end
      end

      private

      def exclude_methods(mod, *method_or_methods)
        @profile.exclude_methods!(mod, method_or_methods)
      end

      def exclude_singleton_methods(mod, *method_or_methods)
        @profile.exclude_singleton_methods!(mod, method_or_methods)
      end

      def exclude_enumerable(mod, *method_or_methods)
        exclude_methods(mod, [:each, *method_or_methods])
        exclude_methods(mod, ENUMERABLE_NAMES)
      end
    end
  end
end
