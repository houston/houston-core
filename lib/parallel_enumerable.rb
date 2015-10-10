module Enumerable

  def parallel
    ParallelEnumerable.new(self)
  end

end

class ParallelEnumerable

  def initialize(enumerable)
    @enumerable = enumerable
  end



  def each
    enumerable.map do |item|
      Thread.new do
        begin
          yield item
        rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
          Houston.report_exception $!
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end.each(&:join)
  end

  def map
    queue = Queue.new

    each do |item|
      queue << yield(item)
    end

    [].tap do |results|
      results.push queue.pop until queue.empty?
    end
  end



  def method_missing(method_name, *args, &block)
    return super unless enumerable.respond_to?(method_name)

    $stderr.puts "[parallel-enumerable] ##{method_name} is not defined"
    enumerable.public_send(method_name, *args, &block)
  end

private

  attr_reader :enumerable

end
