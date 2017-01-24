module Houston

  def self.try(options, *rescue_from)
    options = { max_tries: options } if options.is_a?(Fixnum)
    options = {} unless options.is_a?(Hash)
    max_tries = options.fetch :max_tries, 3
    base = options.fetch :base, 2
    ignore = options.fetch :ignore, false
    rescue_from = [StandardError] if rescue_from.empty?

    tries = 1
    begin
      yield tries
    rescue *rescue_from
      if tries > max_tries
        return if ignore
        raise
      end
      Rails.logger.warn "\e[31m[try] \e[1m#{$!.class}\e[0;31m: #{$!.message}\e[0m"
      sleep base ** tries
      tries += 1
      retry
    end
  end

  def self.reconnect(options={})
    max_tries = options.fetch(:max_tries, 2)
    tries = 1
    begin
      yield
    rescue exceptions_wrapping(PG::ConnectionBad)
      ActiveRecord::Base.connection.reconnect!
      retry unless (tries += 1) > 2
      raise
    end
  end

end
