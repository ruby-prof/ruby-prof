module RubyProf
  class Profile
    module LegacyMethodElimination
      # eliminate some calls from the graph by merging the information into callers.
      # matchers can be a list of strings or regular expressions or the name of a file containing regexps.
      def eliminate_methods!(matchers)
        RubyProf.deprecation_warning(
          "Method 'eliminate_methods!' is dprecated",
          "Please call 'exclude_methods!' before starting the profile run instead."
        )
        matchers = read_regexps_from_file(matchers) if matchers.is_a?(String)
        eliminated = []
        threads.each do |thread|
          matchers.each{ |matcher| eliminated.concat(eliminate_methods(thread.methods, matcher)) }
        end
        eliminated
      end

      private

      # read regexps from file
      def read_regexps_from_file(file_name)
        matchers = []
        File.open(file_name).each_line do |l|
          next if (l =~ /^(#.*|\s*)$/) # emtpy lines and lines starting with #
          matchers << Regexp.new(l.strip)
        end
      end

      # eliminate methods matching matcher
      def eliminate_methods(methods, matcher)
        eliminated = []
        i = 0
        while i < methods.size
          method_info = methods[i]
          method_name = method_info.full_name
          if matcher === method_name
            raise "can't eliminate root method" if method_info.root?
            eliminated << methods.delete_at(i)
            method_info.eliminate!
          else
            i += 1
          end
        end
        eliminated
      end
    end
  end
end
