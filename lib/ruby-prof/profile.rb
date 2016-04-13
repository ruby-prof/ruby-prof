# encoding: utf-8

require 'ruby-prof/profile/exclude_common_methods'
require 'ruby-prof/profile/legacy_method_elimination'

module RubyProf
  class Profile
    include LegacyMethodElimination

    # Hides methods that, when represented as a call graph, have
    # extremely large in and out degrees and make navigation impossible.
    def exclude_common_methods!
      ExcludeCommonMethods.apply!(self)
    end

    def exclude_methods!(mod, *method_or_methods)
      [method_or_methods].flatten.each do |name|
        exclude_method!(mod, name)
      end
    end

    def exclude_singleton_methods!(mod, *method_or_methods)
      exclude_methods!(mod.singleton_class, *method_or_methods)
    end
  end
end
