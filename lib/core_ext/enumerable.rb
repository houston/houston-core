module CoreExt
  module Enumerable
    
    def take_until
      return to_enum(:take_until) unless block_given?
      
      array = []
      each do |elem|
        return array if yield(elem)
        array << elem
      end
      
      array
    end
    
  end
end

Enumerable.send :include, CoreExt::Enumerable
