root = File.expand_path(File.join(File.dirname(__FILE__), "../../.."))
require File.join(root, "lib/hash_dsl")
require File.join(root, "lib/core_ext/hash")
require File.join(root, "lib/core_ext/kernel")
require File.join(root, "lib/core_ext/exception")
require File.join(root, "lib/houston/boot/triggers")
require File.join(root, "lib/houston/boot/observer")
require File.join(root, "lib/houston/boot/actions")
require File.join(root, "lib/houston/boot/timer")
require File.join(root, "lib/houston/boot/provider")
require File.join(root, "lib/houston/adapters")

module Houston
module_function
  def deprecation_notice(message, stack_offset=1)
    message = message.gsub /<b>(.*)<\/b>/, "\e[1m\\1\e[0;34m"
    puts "\e[34mDEPRECATION: #{message}\e[0;90m\n#{caller[stack_offset]}\e[0m\n\n"
  end



  class Configuration
    attr_reader :observer, :actions, :timer, :oauth_providers

    def initialize
      @root = Rails.root
      @use_ssl = Rails.env.production?
      @oauth_providers = []
      @roles = Hash.new { |hash, key| hash[key] = [] }
      @roles["Team Owner"].push(Proc.new do |team|
        can :manage, team
        can :manage, Project, team_id: team.id
      end)
      @modules = []
    end

    def triggers
      return @triggers if defined?(@triggers)
      @triggers = Houston::Triggers.new(self)
    end

    def observer
      return @observer if defined?(@observer)
      @observer = Houston::Observer.new
    end

    def actions
      return @actions if defined?(@actions)
      @actions = Houston::Actions.new
    end

    def timer
      return @timer if defined?(@timer)
      @timer = Houston::Timer.new
    end




    # Global configuration

    def root(*args)
      if args.any?
        @root = args.first

        # Keep structure.sql in instances' db directory
        ActiveRecord::Tasks::DatabaseTasks.db_dir = root.join("db")

        # Configure Houston
        Houston::Application.paths["config/database"] = root.join("config/database.yml")
        Houston::Application.paths["public"] = root.join("public")
        Houston::Application.paths["log"] = root.join("log/#{Rails.env}.log")
        Houston::Application.paths["tmp"] = root.join("tmp")
        Houston::Application.paths["config/environments"] << root.join("config/environments")

        # ActionCable sets the default path for its config file
        # later on during initialization. We need to override the
        # path just before ActionCable is initialized.
        cable_config = Houston.root.join("config/cable.yml")
        if File.exists?(cable_config)
          ActiveSupport.on_load(:action_cable) do
            Houston::Application.paths["config/cable"] = cable_config

            # Make sure that we've loaded the Instance's config file
            # c.f. https://github.com/rails/rails/blob/v5.0.0.1/actioncable/lib/action_cable/engine.rb#L31
            ActionCable.server.config.cable = Rails.application.config_for(cable_config).with_indifferent_access
          end

          # Make sure that we've loaded the Instance's config file
          # c.f. https://github.com/rails/rails/blob/v5.0.0.1/actioncable/lib/action_cable/engine.rb#L31
          ActionCable.server.config.cable = Rails.application.config_for(cable_config).with_indifferent_access
        else
          Rails.application.config.before_initialize do
            Rails.logger.warn "\e[33m[boot] \e[93m#{cable_config}\e[33m does not exist: you will not be able to use Houston.observer on the client\e[0m"
          end
        end
      end

      @root
    end

    def title(*args)
      @title = args.first if args.any?
      @title ||= "Houston"
    end

    def host(*args)
      if args.any?
        @host = args.first

        if Rails.env.production?
          Houston::Application.config.action_cable.mount_path = nil
          Houston::Application.config.action_cable.url = "wss://#{host}:4200"
          Houston::Application.config.action_cable.allowed_request_origins = %w{http https}
            .map { |protocol| "#{protocol}://#{host}" }
        end
      end
      @host ||= nil
    end

    def use_ssl(*args)
      @use_ssl = args.first if args.any?
      @use_ssl
    end

    def use_ssl?
      @use_ssl
    end

    def secret_key_base(*args)
      return Houston::Application.config.secret_key_base if args.none?
      Houston::Application.config.secret_key_base = args.first
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

    def google_analytics(&block)
      @google_analytics = HashDsl.hash_from_block(block) if block_given?
      @google_analytics ||= {}
    end

    def password_length(*args)
      @password_length = args.first if args.any?
      @password_length ||= 8..128
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

    def oauth(provider_name, &block)
      settings = HashDsl.hash_from_block(block)
      provider = Houston.oauth.get_provider(provider_name)

      raise ArgumentError, "Provider must define a client_id" if settings[:client_id].blank?
      raise ArgumentError, "Provider must define a client_secret" if settings[:client_secret].blank?

      provider.client_id = settings[:client_id]
      provider.client_secret = settings[:client_secret]

      @oauth_providers << provider_name.to_s
    end

    def project_categories(*args)
      @project_categories = args if args.any?
      @project_categories ||= []
    end

    def navigation(*args)
      @navigation = args if args.any?
      return Houston.navigation.slugs unless @navigation
      @navigation & Houston.navigation.slugs
    end

    def project_features(*args)
      @project_features = args if args.any?
      return Houston.project_features.all unless @project_features
      @project_features & Houston.project_features.all
    end



    def project_colors(*args)
      new_hash = Hash.new(ColorValue.new("default", "505050"))
      @project_colors = args.first.each_with_object(new_hash) { |(key, hex), hash| hash[key] = ColorValue.new(key, hex) } if args.any?
      @project_colors ||= new_hash
    end

    def environments(*args)
      @environments = args if args.any?
      @environments ||= []
    end

    def roles
      @roles.keys
    end

    def role(role_name, &abilities_block)
      @roles[role_name].push abilities_block
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

    def configure_team_abilities(context, teammate)
      teammate.roles.each do |role|
        context.can :read, teammate.team
        @roles.fetch(role).each do |abilities_block|
          context.instance_exec(teammate.team, &abilities_block)
        end
      end
    end





    # Modules

    def use(module_name, &block)
      mod = self.module(module_name)
      mod ||= ::Houston::Module.new(module_name).tap { |mod| @modules << mod }
      if mod.accepts_configuration?
        mod.load_configuration(block)
      else raise ArgumentError, "#{module_name} does not accept configuration"
      end if block_given?
      mod.dependencies.each(&method(:use))
      mod
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





    # Actions and Triggers

    def action(name, required_params=[], &block)
      actions.define(name, required_params, &block)
    end

    def on(*args, &block)
      event_name, action_name = extract_trigger_and_action!(args)
      event = Houston.events[event_name]

      unless event
        puts "\e[31mUnregistered event: \e[1m#{event_name}\e[0;90m\n#{caller[0]}\e[0m\n\n"
        return
      end

      action = assert_action! action_name, event.params, &block
      action.assert_required_params! event.params

      triggers.on event_name, action_name
      action
    end

    def every(*args, &block)
      interval, action_name = extract_trigger_and_action!(args)
      action = assert_action! action_name, &block
      action.assert_required_params! []
      triggers.every interval, action_name
      action
    end

    private def extract_trigger_and_action!(args)
      if args.first.is_a?(Hash)
        return args.shift.to_a[0] if args.first.one?
        raise ArgumentError, "Unrecognized trigger: #{args.inspect}"
      end
      return args.shift(2) if args.length >= 2
      raise NotImplementedError, "I haven't been programmed to extract trigger and action_name from #{args.inspect}"
    end

    private def assert_action!(name, required_params=[], &block)
      if block_given?
        action name, required_params, &block
      elsif action = actions[name]
        action
      else
        raise ArgumentError, "An action named #{name.inspect} is not defined"
      end
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
      puts "\e[31mMissing Configuration option: \e[1m#{name}\e[0;90m\n#{caller[0]}\e[0m\n\n"
      nil
    end

  end



  class Module
    attr_reader :name

    def initialize(module_name)
      @name = module_name.to_s
    end

    def accepts_configuration?
      namespace.respond_to?(:config)
    end

    def load_configuration(moduleconfig)
      namespace.config(&moduleconfig)
    end

    def dependencies
      namespace.respond_to?(:dependencies) ? namespace.dependencies : []
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





  class ColorValue
    attr_reader :name
    attr_reader :hex

    def initialize(name, hex)
      @name = name
      @hex = hex
    end

    def as_json(options={})
      name
    end

    def to_s
      name
    end

    def rgb
      "rgb(#{@hex.scan(/../).map { |s| s.to_i(16) }.join(", ")})"
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

  def triggers
    config.triggers
  end

  def observer
    config.observer
  end

  def actions
    config.actions
  end

  def timer
    config.timer
  end

  def root
    config.root
  end

end
