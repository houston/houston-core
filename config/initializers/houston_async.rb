module Houston

  # Rescues exceptions and reports them
  def self.async(do_async=true)
    return yield unless do_async
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.verify!
        begin
          yield
        rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
          Houston.report_exception($!)
        ensure
          Rails.logger.flush # http://stackoverflow.com/a/3516003/731300
        end
      end
    end
  end

  # Allows exceptions to bubble up
  def self.async!(do_async=true)
    return yield unless do_async
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.verify!
        begin
          yield
        ensure
          Rails.logger.flush # http://stackoverflow.com/a/3516003/731300
        end
      end
    end
  end

end
