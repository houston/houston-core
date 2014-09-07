module Houston
  
  def self.async
    Thread.new do
      begin
        yield
      rescue
        Houston.report_exception($!)
      end
    end
  end
  
end
