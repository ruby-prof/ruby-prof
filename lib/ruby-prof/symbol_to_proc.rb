unless (:a.respond_to?(:to_proc))
 class Symbol
   def to_proc
      proc {|stuff| stuff.send(self)}
   end
 end
end
 
