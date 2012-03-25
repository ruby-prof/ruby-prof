# encoding: utf-8

require 'set'
module RubyProf
  class Profile
    def post_process

    end
    
    # this method gets called internally when profiling is stopped.
    # it determines for each call_info whether it is minimal: a
    # call_info is minimal in a call tree if the call_info is not a
    # descendant of a call_info of the same method
    def compute_minimality
      return
      threads.each do |threadid, method_infos|
        root_methods = method_infos.select{|mi| mi.root?}
        root_methods.each do |mi|
          mi.call_infos.select{|ci| ci.root?}.each do |call_info_root|
            call_info_root.compute_minimality(Set.new)
          end
        end
      end
    end

    # eliminate some calls from the graph by merging the information into callers.
    # matchers can be a list of strings or regular expressions or the name of a file containing regexps.
    def eliminate_methods!(matchers)
      matchers = read_regexps_from_file(matchers) if matchers.is_a?(String)
      eliminated = []
      threads.each do |thread|
        matchers.each{ |matcher| eliminated.concat(eliminate_methods(thread.methods, matcher)) }
      end
      compute_minimality # is this really necessary?
      eliminated
    end

    def dump
      threads.each do |thread_id, methods|
        $stderr.puts "Call Info Dump for thread id #{thread_id}"
        methods.each do |method_info|
          $stderr.puts method_info.dump
        end
      end
    end

    private

    # read regexps from file
    def read_regexps_from_file(file_name)
      matchers = []
      File.open(matchers).each_line do |l|
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
