module Houston
  
  def self.report_exception(exception, other_data={})
    raise if Rails.env.test? || Rails.env.development?
    if defined?(Airbrake)
      Rails.logger.debug "[error] reporting to Airbrake"
      Airbrake.notify(exception, other_data)
    end
  end
  
end
