module Houston
  
  def self.try(max_tries, *rescue_from)
    tries = 0
    begin
      yield
    rescue *rescue_from
      raise unless (tries += 1) <= max_tries
      sleep 2 ** tries
      retry
    end
  end
  
end
