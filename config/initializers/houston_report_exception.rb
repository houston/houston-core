module Houston
  
  def self.report_exception(exception, other_data={})
    raise if Rails.env.test? || Rails.env.development?
    if defined?(Airbrake)
      case exception
      when Faraday::HTTP::Error
       (other_data[:parameters] ||= {}).merge!(_normalize_faraday_env(exception.env))
      end
      Airbrake.notify(exception, other_data)
    end
  rescue Exception => e
    Rails.logger.error "\e[31;1mAn error occurred reporting the exception: \e[0;31m#{e.class}: #{e.message}\n   #{e.backtrace.join("\n  ")}\e[0m"
  end
  
  def self._normalize_faraday_env(env)
    env.except(:response).tap do |env|
      env[:url] = env[:url].to_s
    end
  end
  
end
