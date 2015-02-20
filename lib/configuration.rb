root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require File.join(root, "lib/core_ext/hash")

$:.unshift File.expand_path(File.join(root, "app/adapters"))
require "houston/adapters"

module Houston
  class Configuration
    attr_reader :timers
    
    def initialize
      @modules = []
      @gems = []
      @navigation_renderers = {}
      @authentication_strategy = :database
      @authentication_strategy_configuration = {}
      @ticket_tracker_configuration = {}
      @ci_server_configuration = {}
      @error_tracker_configuration = {}
      @timers = []
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
    
    def mailer_from
      require "mail"
      
      Mail::Address.new.tap do |email|
        email.display_name = title
        email.address = mailer_sender
      end.to_s
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
    
    def intercom(&block)
      @intercom = HashDsl.hash_from_block(block) if block_given?
      @intercom ||= {}
    end
    
    def use_intercom?
      intercom[:app_id].present?
    end
    
    def project_categories(*args)
      @project_categories = args if args.any?
      @project_categories ||= []
    end
    
    def navigation(*args)
      @navigation = args if args.any?
      @navigation ||= []
    end
    
    def add_navigation_renderer(name, &block)
      @navigation_renderers[name] = block
    end
    
    def get_navigation_renderer(name)
      @navigation_renderers.fetch(name)
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
    
    def ticket_types(*args)
      if args.any?
        @ticket_types = args.first
        @ticket_types.default = "EFEFEF"
      end
      @ticket_types.keys
    end
    
    def ticket_colors
      @ticket_types
    end
    
    
    
    
    
    def parse_ticket_description(ticket=nil, &block)
      if block_given?
        @parse_ticket_description_proc = block
      elsif ticket
        @parse_ticket_description_proc.call(ticket) if @parse_ticket_description_proc
      end
    end
    
    def identify_committers(commit=nil, &block)
      if block_given?
        @identify_committers_proc = block
      elsif commit
        @identify_committers_proc ? Array(@identify_committers_proc.call(commit)) : [commit.committer_email]
      end
    end
    
    
    
    
    
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
    
    def github(&block)
      @github_configuration = HashDsl.hash_from_block(block) if block_given?
      @github_configuration ||= {}
    end
    
    def gemnasium(&block)
      @gemnasium_configuration = HashDsl.hash_from_block(block) if block_given?
      @gemnasium_configuration ||= {}
    end
    
    def supports_pull_requests?
      github[:organization].present?
    end
    
    
    
    
    
    # Modules
    
    def use(module_name, args={}, &block)
      @modules << ::Houston::Module.new(module_name, args, &block)
    end
    attr_reader :modules
    
    def uses?(module_name)
      module_name = module_name.to_s
      modules.any? { |mod| mod.name == module_name }
    end
    
    def module(module_name)
      module_name = module_name.to_s
      modules.detect { |mod| mod.name == module_name }
    end
    
    def gem(*gemspec)
      @gems << gemspec
    end
    
    def gems
      @gems + modules.select(&:bundle?).map(&:gemspec)
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
    
    
    
    
    
    # Events
    
    def on(event, &block)
      Houston.observer.on(event, &block)
    end
    
    def at(time, name, options={}, &block)
      @timers.push [:cron, time, name, options, block]
    end
    
    def every(interval, name, options={}, &block)
      @timers.push [:every, interval, name, options, block]
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
    
    def initialize(module_name, gemconfig={}, &moduleconfig)
      @name = module_name.to_s
      gem_name = "houston-#{name}"
      @bundle = gemconfig.fetch(:bundle, true)
      @gemspec = [gem_name, gemconfig.pick(:group, :groups, :git, :path, :name, :branch, :github,
        :ref, :tag, :require, :submodules, :platform, :platforms, :type, :source)]
      @config = moduleconfig
    end
    
    attr_reader :name, :gemspec, :config
    
    def engine
      namespace::Engine
    end
    
    def bundle?
      @bundle
    end
    
    def path
      "/#{name}"
    end
    
    def namespace
      @namespace ||= "houston/#{name}".camelize.constantize
    end
    
  end
  
  
  
  class Dependencies
    
    def initialize
      @values = []
    end
    
    attr_reader :values
    
    def gem(slug, target_versions=[], options={})
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
        begin
          invoke_callback(block, *args)
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end
    
    def invoke_callback(block, *args)
      block.call(*args)
    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
      Houston.report_exception($!)
    end
    
    def observers_of(event)
      observers[event] ||= []
    end
    
    attr_reader :observers
    
  end
  
  
  
  class Jobs
    
    def run_async(slug)
      block = find_timer_block!(slug)
      Thread.new do
        run! "#{slug}/manual", block
      end
    end
    
    def run_job(job)
      slug = job.tags.first
      block = find_timer_block!(slug)
      run! "#{slug}/#{job.original}", block
    end
    
  private
    
    def find_timer_block!(slug)
      timer = Houston.config.timers.detect { |(_, _, name, _, _)| name == slug }
      raise ArgumentError, "#{slug} is not a job" unless timer
      timer.last
    end
    
    def run!(tag, block)
      Rails.logger.info "\e[34m[#{tag}] Running job\e[0m"
      block.call
      
    rescue SocketError,
           Errno::ECONNREFUSED,
           Errno::ETIMEDOUT,
           Faraday::Error::ConnectionFailed,
           Faraday::HTTP::ServerError,
           Rugged::NetworkError,
           Unfuddle::ConnectionError,
           exceptions_wrapping(PG::ConnectionBad)
      Rails.logger.error "\e[31m[#{tag}] #{$!.class}: #{$!.message} [ignored]\e[0m"
    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
      Rails.logger.error "\e[31m[#{tag}] \e[1m#{$!.message}\e[0m"
      Houston.report_exception($!, parameters: {job_name: name}) # <-- no job id!
    ensure
      ActiveRecord::Base.clear_active_connections!
    end
    
    def exceptions_wrapping(error_class)
      m = Module.new
      (class << m; self; end).instance_eval do
        define_method(:===) do |err|
          err.respond_to?(:original_exception) && error_class === err.original_exception
        end
      end
      m
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
  
  def jobs
    @jobs ||= Jobs.new
  end
  
  def github
    @github ||= Octokit::Client.new(access_token: config.github[:access_token], auto_paginate: true)
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
    "CCCCCC"
  end
  
  def name
    "No tag"
  end
  
  def position
    999
  end
  
end




# Load configuration file
require (ENV["HOUSTON_CONFIG"] || File.join(root, "config/config.rb"))
