require "fnord-client"
require "active_support/notifications"
require "active_support/benchmarkable"


class Changelog::Notifier
  include ActiveSupport::Benchmarkable
  
  class Configuration < Struct.new(:application, :host, :port, :protocol)
  end
  
  
  def self.setup
    config = Configuration.new
    yield config
    raise ArgumentError.new("set application for Changelog::Notifier") unless config.application
    Changelog::Notifier.new({
      application: config.application,
      host: config.host || "localhost",
      port: config.port || 1337,
      protocol: config.protocol || :udp
    })
  end
  
  def initialize(options={})
    @application = options[:application]
    Fnord::Client.namespace = "changelog"
    @notifier = Fnord::Client.new(options[:host], options[:port], protocol: options[:protocol])
    
    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
      notify :response, {time: (finish - start) * 1000, status: payload[:status]}
    end
  end
  
  def notify(event_type, payload)
    payload = payload.merge(application: @application)
    benchmark "[changelog:notify] #{event_type} #{format_hash payload}" do
      @notifier.event event_type, payload
    end
  end
  
  delegate :logger, :to => :Rails
  
  
private
  
  def format_hash(hash)
    hash.map { |key, value| "#{key}: #{value.inspect}" }.join(", ")
  end
  
end


Changelog::Notifier.setup do |config|
  config.application = "changelog"
  config.host = "localhost"
  config.port = 2323
end
