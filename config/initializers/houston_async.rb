module Houston

  def self.async
    Thread.new do
      begin
        yield
      rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
        Houston.report_exception($!)
      end
    end
  end

end
