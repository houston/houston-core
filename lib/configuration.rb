root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require File.join(root, "lib/core_ext/hash")
require File.join(root, "lib/core_ext/kernel")
require File.join(root, "lib/core_ext/exception")
require File.join(root, "lib/houston_observer")

$:.unshift File.expand_path(File.join(root, "app/adapters"))
require "houston/adapters"

module Houston
  class Configuration
    attr_reader :timers

    def initialize
      @root = Rails.root
      @modules = []
      @gems = []
      @navigation_renderers = {}
      @user_options = {}
      @available_project_features = {}
      @ticket_types = {}
      @authentication_strategy = :database
      @authentication_strategy_configuration = {}
      @ticket_tracker_configuration = {}
      @ci_server_configuration = {}
      @error_tracker_configuration = {}
      @timers = []
    end





    # Global configuration

    def root(*args)
      return @root if args.none?
      @root = args.first

      # Keep structure.sql in instances' db directory
      ActiveRecord::Tasks::DatabaseTasks.db_dir = root.join("db")

      # Configure Houston
      Houston::Application.paths["config/database"] = root.join("config/database.yml")
      Houston::Application.paths["public"] = root.join("public")
      Houston::Application.paths["log"] = root.join("log/#{Rails.env}.log")
      Houston::Application.paths["tmp"] = root.join("tmp")
      Houston::Application.paths["config/environments"] << root.join("config/environments")

      # TODO: finish this
      Rails.application.assets = Sprockets::Environment.new(root) do |env|
        env.version = Rails.env

        path = "#{Houston.root}/tmp/cache/assets/#{Rails.env}"
        env.cache = Sprockets::Cache::FileStore.new(path)

        env.context_class.class_eval do
          include ::Sprockets::Rails::Helper
        end
      end
    end

    def title(*args)
      @title = args.first if args.any?
      @title ||= "Houston"
    end

    def host(*args)
      @host = args.first if args.any?
      @host ||= nil
    end

    def time_zone(*args)
      return Rails.application.config.time_zone if args.none?
      Rails.application.config.time_zone = args.first
      Time.zone = args.first
    end

    def mailer_sender(*args)
      if args.any?
        @mailer_sender = args.first
        (Rails.application.config.action_mailer.default_options ||= {}).merge!(from: @mailer_sender)
      end
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
      root.join("config", "keypair.pem")
    end

    def parallelization(*args)
      @parallelization = args.first if args.any?
      @parallelization ||= :off
    end

    def parallelize?
      parallelization == :on
    end

    def smtp(&block)
      Rails.application.config.action_mailer.smtp_settings = HashDsl.hash_from_block(block) if block_given?
      Rails.application.config.action_mailer.smtp_settings
    end

    def s3(&block)
      @s3 = HashDsl.hash_from_block(block) if block_given?
      @s3 ||= {}
    end

    def engineyard(&block)
      @engineyard = HashDsl.hash_from_block(block) if block_given?
      @engineyard ||= {}
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



    def add_user_option(slug, &block)
      dsl = FormBuilderDsl.new
      dsl.instance_eval(&block)
      form = dsl.form
      form.slug = slug

      @user_options[slug] = form
    end

    def user_options
      @user_options.values
    end



    def project_features(*args)
      @project_features = args if args.any?
      return @available_project_features.keys unless @project_features
      @project_features & @available_project_features.keys
    end

    def get_project_feature(slug)
      @available_project_features[slug]
    end

    def add_project_feature(slug, &block)
      dsl = ProjectFeatureDsl.new
      dsl.instance_eval(&block)
      feature = dsl.feature
      feature.slug = slug
      raise ArgumentError, "Project Feature must supply name, but #{slug.inspect} doesn't" unless feature.name
      raise ArgumentError, "Project Feature must supply icon, but #{slug.inspect} doesn't" unless feature.icon
      raise ArgumentError, "Project Feature must supply path lambda, but #{slug.inspect} doesn't" unless feature.path_block

      @available_project_features[slug] = feature
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





    #

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





    def load(glob)
      __file__ = caller[0].split(":")[0]
      glob << ".rb" unless glob.end_with? ".rb"
      Dir.glob("#{File.dirname(__file__)}/#{glob}").each do |file|
        next if File.directory?(file)
        require file
      end
    end



    # Validation

    def validate!
      raise MissingConfiguration, <<-ERROR unless mailer_sender

        Houston requires a default email address to be supplied for mailers
        You can set the address by adding the following line to config/config.rb:

          mailer_sender "houston@my-company.com"

        ERROR
    end

    def method_missing(name, *args, &block)
      puts "\e[33mMissing Configuration option: #{name}\e[0m"
      nil
    end

  end



  class Module
    attr_reader :name

    def initialize(module_name, options={}, &moduleconfig)
      @name = module_name.to_s

      if namespace.respond_to?(:config) && block_given?
        namespace.config(&moduleconfig)
      elsif block_given? && !namespace.respond_to?(:config)
        raise "#{name} does not accept configuration"
      end
    end

    def engine
      namespace::Engine
    end

    def path
      "/#{name}"
    end

    def namespace
      @namespace ||= "houston/#{name}".camelize.constantize
    end
  end



  class Dependencies
    attr_reader :values

    def initialize
      @values = []
    end

    def gem(slug, target_versions=[], options={})
      @values << options.merge(type: :gem, slug: slug, target_versions: target_versions)
    end
  end



  class HashDsl
    attr_reader :hash
    alias :to_hash :hash
    alias :to_h :hash

    def initialize
      @hash = {}
    end

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



  class ProjectFeature
    attr_accessor :name, :slug, :icon, :path_block, :ability_block, :fields

    def initialize
      self.fields = []
    end

    def project_path(project)
      path_block.call project
    end

    def permitted?(ability, project)
      return true if ability_block.nil?
      ability_block.call ability, project
    end
  end



  class ProjectFeatureDsl
    attr_reader :feature

    def initialize
      @feature = ProjectFeature.new
    end

    def name(value)
      feature.name = value
    end

    def icon(value)
      feature.icon = value
    end

    def path(&block)
      feature.path_block = block
    end

    def ability(&block)
      feature.ability_block = block
    end

    def field(slug, &block)
      dsl = FormBuilderDsl.new
      dsl.instance_eval(&block)
      form = dsl.form
      form.slug = slug
      feature.fields.push form
    end
  end



  class ProjectFeatureForm
    attr_accessor :slug, :name, :render_block

    def render(view, f)
      view.instance_exec(f, &render_block).html_safe
    end
  end

  class FormBuilderDsl
    attr_reader :form

    def initialize
      @form = ProjectFeatureForm.new
    end

    def name(value)
      form.name = value
    end

    def html(&block)
      form.render_block = block
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
      Houston.report_exception($!, parameters: {job_name: tag}) # <-- no job id!
    ensure
      ActiveRecord::Base.clear_active_connections!
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
    @configuration ||= Configuration.new
    if block_given?
      @configuration.instance_eval(&block)
      @configuration.validate!
    end
    @configuration
  end


  def self.root
    config.root
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
