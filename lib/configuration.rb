require 'unfuddle/neq'
require 'color_value'

class Configuration
  include Unfuddle::NeqHelper
  
  def title(value)
    Rails.application.config.title = value
  end
  
  def colors(value)
    Rails.application.config.colors = \
      value.each_with_object({}) { |(key, hex), hash| hash[key] = ColorValue.new(hex) }
  end
  
  def ticket_system(value)
  end
  
  def severities(values=nil)
    @severities = values if values
    @severities
  end
  
  def error_tracker(value)
  end
  
  def default_environments(value)
    Rails.application.config.default_environments = value
  end
  
  def unfuddle(value)
    Rails.application.config.unfuddle = value
    Unfuddle.config(value)
  end
  
  def new_relic(value)
    Rails.application.config.new_relic = value
  end
  
  def errbit(value)
    Rails.application.config.errbit = value
  end
  
  def smtp(value)
    Rails.application.config.action_mailer.smtp_settings = value
  end
  
  def key_dependencies(&block)
    if block_given?
      dependencies = Changelog::Dependencies.new
      dependencies.instance_eval(&block)
      @dependencies = dependencies.names
    end
    @dependencies || []
  end
  
  def websocket_server_port(*args)
    @websocket_server_port = args.first if args.length == 1
    @websocket_server_port
  end
  
  def upd_acceptor_port(*args)
    @upd_acceptor_port = args.first if args.length == 1
    @upd_acceptor_port
  end
  
  def queues(value)
    Rails.application.config.queues = value
  end
  
  def on(event, &block)
    Changelog.observer.on(event, &block)
  end
  
end

class Changelog::Dependencies
  
  def initialize
    @values = []
  end
  
  def gem(name)
    @values << [:gem, name]
  end
  
  def names
    @values.map { |pair| pair[1] }
  end
  
end

class Changelog::Observer
  
  def on(event, &block)
    observers_of(event).push(block)
    nil
  end
  
  def fire(event, *args)
    observers_of(event).each do |block|
      block.call(*args)
    end
    nil
  end
  
private
  
  def observers_of(event)
    observers[event] ||= []
  end
  
  def observers
    @observers ||= {}
  end

end

def Changelog.config(&block)
  if block_given?
    Rails.application.config.obj = Configuration.new
    Rails.application.config.obj.instance_eval(&block)
  end
  Rails.application.config.obj
end

def Changelog.observer
  @observer ||= Changelog::Observer.new
end
