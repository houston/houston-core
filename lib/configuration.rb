require 'unfuddle/neq'

class Configuration
  include Unfuddle::NeqHelper
  
  def title(value)
    Rails.application.config.title = value
  end
  
  def ticket_system(value)
  end
  
  def unfuddle(value)
    Rails.application.config.unfuddle = value
    Unfuddle.config(value)
  end
  
  def smtp(value)
    Rails.application.config.action_mailer.smtp_settings = value
  end
  
  def queues(value)
    Rails.application.config.queues = value
  end
  
end

def Changelog.config(&block)
  configuration = Configuration.new
  configuration.instance_eval(&block)
end
