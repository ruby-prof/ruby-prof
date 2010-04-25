require 'set'
module RubyProf
  class Result
    # this method gets called internally when profiling is stopped.
    # it determines for each call_info whether it is minimal: a
    # call_info is minimal in a call tree if the call_info is not a
    # descendant of a call_info of the same method
    def compute_minimality
      threads.each do |threadid, method_infos|
        root_methods = method_infos.select{|mi| mi.root?}
        root_methods.each do |mi|
          mi.call_infos.select{|ci| ci.root?}.each do |call_info_root|
            call_info_root.compute_minimality(Set.new)
          end
        end
      end
    end
  end
end
