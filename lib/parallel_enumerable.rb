module ParallelEnumerable
  
  def parallel_each
    map do |item|
      Thread.new do
        yield item
      end
    end.each(&:join)
  end
  
  def parallel_map
    queue = Queue.new
    
    parallel_each do |item|
      queue << yield(item)
    end
    
    [].tap do |results|
      results.push queue.pop until queue.empty?
    end
  end
  
end
