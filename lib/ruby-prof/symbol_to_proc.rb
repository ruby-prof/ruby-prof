unless (:a.respond_to?(:to_proc))
puts 'adding symbol'
 class Symbol
   def to_proc
      proc {|stuff| stuff.send(self)}
   end
 end
end
 
