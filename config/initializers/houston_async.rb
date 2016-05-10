module Houston

  # Rescues exceptions and reports them
  def self.async
    Thread.new do
      begin
        yield
      rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
        Houston.report_exception($!)
      ensure
        ActiveRecord::Base.clear_active_connections!
        Rails.logger.flush # http://stackoverflow.com/a/3516003/731300
      end
    end
  end

  # Allows exceptions to bubble up
  def self.async!
    Thread.new do
      begin
        yield
      ensure
        ActiveRecord::Base.clear_active_connections!
        Rails.logger.flush # http://stackoverflow.com/a/3516003/731300
      end
    end
  end

end
