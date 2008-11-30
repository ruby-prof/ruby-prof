unless Enumerable.method_defined?(:group_by)
  module Enumerable
    def group_by
      inject(Hash.new) do |result, element|
        (result[yield(element)] ||= []) << element
        result
      end
    end
  end
end
