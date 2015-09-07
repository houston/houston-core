require "active_support/duration"


module DurationExtensions
  
  def from(*args)
    since(*args)
  end
  
  def after(*args)
    since(*args)
  end
  
  def before(*args)
    ago(*args)
  end
  
end


ActiveSupport::Duration.send(:include, DurationExtensions)
