# !todo: remove this requirement
$:.unshift File.expand_path("./lib/unfuddle/lib")
require 'unfuddle/neq'

module Houston
  class Configuration
    include Unfuddle::NeqHelper
    
    def title(*args)
      @title = args.first if args.any?
      @title ||= "Houston"
    end
    
    def mailer_sender(*args)
      @mailer_sender = args.first if args.any?
      @mailer_sender ||= nil
    end
    
    
    
    # Components
    
    def ticket_system(*args, &block)
      @ticket_system_configuration = HashDsl.hash_from_block(block) if block_given?
      
      # Currently Unfuddle is the only supported ticket system
      :unfuddle
    end
    attr_reader :ticket_system_configuration
    
    def error_tracker(*args, &block)
      @error_tracker_configuration = HashDsl.hash_from_block(block) if block_given?
      
      # Currently Errbit is the only supported error tracker
      :errbit
    end
    attr_reader :error_tracker_configuration
    alias :errbit :error_tracker_configuration
    
    
    
    
    
    
    def new_relic(&block)
      @new_relic_configuration = HashDsl.hash_from_block(block) if block_given?
      @new_relic_configuration ||= {}
    end
    
    
    
    # Email
    
    def smtp(&block)
      @smtp = HashDsl.hash_from_block(block) if block_given?
      @smtp ||= {}
    end
    
    
    
    # Configuration
    
    def key_dependencies(&block)
      if block_given?
        dependencies = Houston::Dependencies.new
        dependencies.instance_eval(&block)
        @dependencies = dependencies.names
      end
      @dependencies || []
    end
    
    def queues(*args)
      @queues = args.first if args.any?
      @queues ||= []
    end
    
    def colors(*args)
      @colors = args.first.each_with_object({}) { |(key, hex), hash| hash[key] = ColorValue.new(hex) } if args.any?
      @colors ||= []
    end
    
    def severities(*args)
      @severities = args.first if args.any?
      @severities ||= []
    end
    
    
    
    # Events
    
    def on(event, &block)
      Houston.observer.on(event, &block)
    end
    
    def cron(&block)
      @whenever_configuration = block if block_given?
      @whenever_configuration ||= nil
    end
    
    
    
    # Validation
    
    def validate!
      raise MissingConfiguration, <<-ERROR unless mailer_sender
        
        Houston requires a default email address to be supplied for mailers
        You can set the address by adding the following line to config/config.rb:
          
          mailer_sender "houston@my-company.com"
        
        ERROR
    end
    
  end
  
  
  
  class Dependencies
    
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
  
  
  
  class HashDsl
    
    def initialize
      @hash = {}
    end
    
    attr_reader :hash
    alias :to_hash :hash
    
    def self.from_block(block)
      HashDsl.new.tap { |dsl| dsl.instance_eval(&block) }
    end
    
    def self.hash_from_block(block)
      from_block(block).to_hash
    end
    
    def method_missing(method_name, *args, &block)
      if block_given?
        @hash[method_name] = HashDsl.hash_from_block(block)
      elsif args.length == 1
        @hash[method_name] = args.first
      else
        super
      end
    end
    
  end
  
  
  
  class ColorValue
    
    def initialize(hex)
      @hex = hex
    end
    
    def to_s
      @hex
    end
    
    def rgb
      "rgb(#{@hex.scan(/../).map { |s| s.to_i(16) }.join(", ")})"
    end
    
  end
  
  
  
  class Observer
    
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
  
  
  
  class NotConfigured < RuntimeError
    def initialize(message = "Houston has not been configured. Please load config/config.rb before calling Houston.config")
      super
    end
  end
  
  class MissingConfiguration < RuntimeError; end
  
  
  
module_function
  
  def config(&block)
    if block_given?
      @configuration = Configuration.new
      @configuration.instance_eval(&block)
      @configuration.validate!
    end
    @configuration || (raise NotConfigured)
  end
  
  def observer
    @observer ||= Observer.new
  end
  
end



# Load configuration file
require File.expand_path("./config/config.rb")
# require Rails.root.join('config', 'config.rb').to_s
