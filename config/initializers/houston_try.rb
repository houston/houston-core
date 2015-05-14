module Houston
  
  def self.try(options, *rescue_from)
    options = { max_tries: options } if options.is_a?(Fixnum)
    options = {} unless options.is_a?(Hash)
    max_tries = options.fetch :max_tries, 3
    base = options.fetch :base, 2
    
    tries = 1
    begin
      yield tries
    rescue *rescue_from
      raise unless (tries += 1) <= max_tries
      sleep base ** tries
      retry
    end
  end
  
end
