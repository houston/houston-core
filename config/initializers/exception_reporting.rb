module Houston
  
  def self.report_exception(exception, other_data={})
    if defined?(Airbrake)
      Rails.logger.debug "[error] reporting to Airbrake"
      Airbrake.notify(exception, other_data)
    end
  end
  
end
