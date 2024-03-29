module Houston

  def self.report_exception(exception, other_data={})
    if Rails.env.test? || Rails.env.development?
      Rails.logger.error "\e[31;1m#{exception.class}: #{exception.message}\n#{exception.backtrace.join("\n  ")}\e[0m"
      return
    end

    begin
      Rails.logger.error "#{exception.class}: #{exception.message}\n#{exception.backtrace.join("\n  ")}"

      if defined?(Airbrake)
        other_data[:parameters] ||= {}
        case exception
        when Faraday::ServerError, Faraday::ClientError
          other_data[:parameters].merge!(_normalize_faraday_env(exception.env))
        end
        other_data[:parameters].merge!(exception.additional_information)
        Airbrake.notify(exception, other_data)
      end
    rescue Exception => e
      Rails.logger.error "\e[31;1mAn error occurred reporting the exception: \e[0;31m#{e.class}: #{e.message}\n   #{e.backtrace.join("\n  ")}\e[0m"
    end
  end

  def self._normalize_faraday_env(env)
    env.to_h.except(:response).tap do |env|
      env[:url] = env[:url].to_s
    end
  end

end
