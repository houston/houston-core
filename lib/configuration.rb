require File.join(File.dirname(__FILE__), 'core_ext/hash')

$:.unshift File.expand_path("./app/adapters")
require "houston/adapters"

module Houston
  class Configuration
    
    def initialize
      @modules = []
      @authentication_strategy = :database
      @authentication_strategy_configuration = {}
      @ticket_tracker_configuration = {}
      @ci_server_configuration = {}
      @error_tracker_configuration = {}
    end
    
    
    
    
    
    # Global configuration
    
    def title(*args)
      @title = args.first if args.any?
      @title ||= "Houston"
    end
    
    def host(*args)
      @host = args.first if args.any?
      @host ||= nil
    end
    
    def mailer_sender(*args)
      @mailer_sender = args.first if args.any?
      @mailer_sender ||= nil
    end
    
    def passphrase(*args)
      @passphrase = args.first if args.any?
      @passphrase ||= nil
    end
    
    def keypair
      Rails.root.join('config', 'keypair.pem')
    end
    
    def parallelization(*args)
      @parallelization = args.first if args.any?
      @parallelization ||= :off
    end
    
    def parallelize?
      parallelization == :on
    end
    
    def smtp(&block)
      @smtp = HashDsl.hash_from_block(block) if block_given?
      @smtp ||= {}
    end
    
    def project_categories(*args)
      @project_categories = args if args.any?
      @project_categories ||= []
    end
    
    def project_colors(*args)
      @project_colors = args.first.each_with_object({}) { |(key, hex), hash| hash[key] = ColorValue.new(hex) } if args.any?
      @project_colors ||= []
    end
    
    def environments(*args)
      @environments = args if args.any?
      @environments ||= []
    end
    
    def roles(*args)
      @roles = args if args.any?
      ["Guest"] + (@roles ||= [])
    end
    
    def default_role
      "Guest"
    end
    
    def project_roles(*args)
      @project_roles = args if args.any?
      ["Follower"] + (@project_roles ||= [])
    end
    
    
    
    def identify_committers(&block)
      @identify_committers_proc = block
    end
    
    attr_reader :identify_committers_proc
    
    
    
    
    
    # Authentication options
    
    def authentication_strategy(strategy=nil, &block)
      @authentication_strategy = strategy if strategy
      @authentication_strategy_configuration = HashDsl.hash_from_block(block) if block_given?
      
      @authentication_strategy
    end
    attr_reader :authentication_strategy_configuration
    
    def devise_configuration
      # Include default devise modules. Others available are:
      #      :registerable,
      #      :encryptable,
      #      :confirmable,
      #      :lockable,
      #      :timeoutable,
      #      :omniauthable
      
      configuration = [:database_authenticatable, :token_authenticatable]
      unless Rails.env.test? # <-- !todo: control when custom strategies are employed in the test suite
        configuration << :ldap_authenticatable if authentication_strategy == :ldap
      end
      configuration.concat [
       :recoverable,
       :rememberable,
       :trackable,
       :validatable,
       :invitable ]
    end
    
    
    
    
    
    # Permissions
    
    def abilities(&block)
      @abilities_block = block
    end
    
    def defines_abilities?
      @abilities_block.present?
    end
    
    def configure_abilities(context, user)
      context.instance_exec(user, &@abilities_block)
    end
    
    
    
    
    
    # Adapters
    
    Houston::Adapters.each do |name, path|
      module_eval <<-RUBY
        def #{path}(adapter, &block)
          raise ArgumentError, "\#{adapter.inspect} is not a #{name}: known #{name} adapters are: \#{Houston::Adapters::#{name}.adapters.map { |name| ":\#{name.downcase}" }.join(", ")}" unless Houston::Adapters::#{name}.adapter?(adapter)
          raise ArgumentError, "#{path} should be invoked with a block" unless block_given?
          
          configuration = HashDsl.hash_from_block(block)
          
          @#{path}_configuration ||= {}
          @#{path}_configuration[adapter] = configuration
        end
        
        def #{path}_configuration(adapter)
          raise ArgumentError, "\#{adapter.inspect} is not a #{name}: known #{name} adapters are: \#{Houston::Adapters::#{name}.adapters.map { |name| ":\#{name.downcase}" }.join(", ")}"  unless Houston::Adapters::#{name}.adapter?(adapter)
          
          @#{path}_configuration ||= {}
          @#{path}_configuration[adapter] || {}
        end
      RUBY
    end
    
    def new_relic(&block)
      @new_relic_configuration = HashDsl.hash_from_block(block) if block_given?
      @new_relic_configuration ||= {}
    end
    
    def github(&block)
      @github_configuration = HashDsl.hash_from_block(block) if block_given?
      @github_configuration ||= {}
    end
    
    
    
    
    
    # Modules
    
    def use(module_name, *args, &block)
      @modules << ::Houston::Module.new(module_name, *args, &block)
    end
    attr_reader :modules
    
    def uses?(module_name)
      module_name = module_name.to_s
      modules.any? { |mod| mod.name == module_name }
    end
    
    
    
    
    
    # Configuration for Releases
    
    def change_tags(*args)
      if args.any?
        @tag_map = {}
        args.flatten.each_with_index do |hash, position|
          Tag.new(hash.pick(:name, :color).merge(slug: hash[:as], position: position)).tap do |tag|
            @tag_map[tag.slug] = tag
            hash.fetch(:aliases, []).each do |slug|
              @tag_map[slug] = tag
            end
          end
        end
      end
      (@tag_map ||= {}).values.uniq
    end
    
    def fetch_tag(slug)
      tag_map.fetch(slug, NullTag.instance)
    end
    
    attr_reader :tag_map
    
    
    
    
    
    # Configuration for Releases
    
    def key_dependencies(&block)
      if block_given?
        dependencies = Houston::Dependencies.new
        dependencies.instance_eval(&block)
        @dependencies = dependencies.values
      end
      @dependencies || []
    end
    
    def queues(&block)
      if block_given?
        builder = Houston::QueuesBuilder.new
        builder.instance_eval(&block)
        @queues = builder.queues
      end
      @queues ||= []
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
  
  
  
  class Module
    
    def initialize(module_name, *gemconfig, &moduleconfig)
      @name = module_name.to_s
      gem_name = "houston-#{name}"
      @gemspec = [gem_name] + gemconfig
    end
    
    attr_reader :name, :gemspec
    
    def engine
      namespace::Engine
    end
    
    def path
      "/#{name}"
    end
    
    def namespace
      @namespace ||= "houston/#{name}".classify.constantize
    end
    
  end
  
  
  
  class Dependencies
    
    def initialize
      @values = []
    end
    
    attr_reader :values
    
    def gem(slug, target_versions, options={})
      @values << options.merge(type: :gem, slug: slug, target_versions: target_versions)
    end
    
  end
  
  
  
  class HashDsl
    
    def initialize
      @hash = {}
    end
    
    attr_reader :hash
    alias :to_hash :hash
    alias :to_h :hash
    
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
  
  
  
  class QueuesBuilder
    
    def initialize
      @queues = []
    end
    
    def method_missing(slug, *args, &block)
      builder = QueueBuilder.new(slug)
      builder.instance_eval(&block)
      @queues << builder.queue
    end
    
    attr_reader :queues
    
  end
  
  
  
  class QueueBuilder
    
    def initialize(slug)
      @slug = slug.to_s
    end
    
    def name(name)
      @name = name
    end
    
    def description(description)
      @description = description
    end
    
    def where(&block)
      @where = block
    end
    
    def queue
      { slug: @slug,
        name: @name,
        description: @description,
        where: @where }
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
    
    def initialize
      @async = true
      clear!
    end
    
    attr_accessor :async
    
    def on(event, &block)
      observers_of(event).push(block)
      nil
    end
    
    def observed?(event)
      observers_of(event).any?
    end
    
    def fire(event, *args)
      invoker = async ? method(:invoke_callback_async) : method(:invoke_callback)
      observers_of(event).each do |block|
        invoker.call(block, *args)
      end
      nil
    end
    
    def clear!
      @observers = {}
    end
    
  private
    
    def invoke_callback_async(block, *args)
      Thread.new do
        invoke_callback(block, *args)
      end
    end
    
    def invoke_callback(block, *args)
      block.call(*args)
    rescue
      Houston.report_exception($!)
    end
    
    def observers_of(event)
      observers[event] ||= []
    end
    
    attr_reader :observers
    
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



class Tag
  
  def initialize(options={})
    @name = options[:name]
    @slug = options[:slug]
    @color = options[:color]
    @position = options[:position]
  end
  
  attr_reader :name
  attr_reader :slug
  attr_reader :color
  attr_reader :position
  
  def to_partial_path
    "tags/tag"
  end
  
end

class NullTag
  
  def self.instance
    @instance ||= self.new
  end
  
  def nil?
    true
  end
  
  def slug
    nil
  end
  
  def color
    "EFEFEF"
  end
  
  def name
    "&mdash;".html_safe
  end
  
  def position
    999
  end
  
  def to_partial_path
    "tags/null_tag"
  end
  
end




# Load configuration file
require File.expand_path("./config/config.rb")
