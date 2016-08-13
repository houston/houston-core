# This file loads and configures Houston

# Load Houston
require "houston/application"

require_relative "../lib/houston/engine"
require_relative "../lib/slack_helpers"
require_relative "../lib/time_helpers"

# Configure Houston
Houston.config do

  # Required
  # ---------------------------------------------------------------------------
  #
  # The path to this instance.
  # This is required so that Houston can load environment-specific
  # configuration from ./config/environments, write log files to
  # ./logs, and serve static assets from ./public.
  root Pathname.new File.expand_path("../..",  __FILE__)

  # This is the name that will be shown in the banner
  title "Houston"

  # This is the host where Houston will be running
  host "houston.my-company.com"

  # This is the email address for emails send from Houston
  mailer_sender "houston@my-company.com"

  # This is the passphrase you used when generating config/keypair.pem
  # Houston will use the keypair to encrypt and decrypt sensitive data
  # To generate a new keypair.pem, execute these commands:
  #
  #   openssl genrsa -des3 -out config/private.pem 2048
  #   openssl rsa -in config/private.pem -out config/public.pem -outform PEM -pubout
  #   cat config/private.pem config/public.pem >> config/keypair.pem
  #
  passphrase ENV["HOUSTON_PASSPHRASE"]

  # This is the SMTP server Houston will use to send emails
  smtp do

    # Configuration for a local SMTP server
    # address "10.10.10.10"
    # port 25
    # domain "10.10.10.10"

    # Configuration for an SMTP service (like Mailgun)
    # authentication :plain
    # address "smtp.mailgun.org"
    # port 587
    # domain "my-company.mailgun.org"
    # user_name ENV["HOUSTON_MAILGUN_USERNAME"]
    # password ENV["HOUSTON_MAILGUN_PASSWORD"]

  end

  # These are the colors available for projects
  project_colors(
    "teal"          => "39b3aa",
    "sky"           => "239ce7",
    "sea"           => "335996",
    "indigo"        => "7d63b8",
    "thistle"       => "b35ab8",
    "tomato"        => "e74c23",
    "bark"          => "756e54",
    "hazelnut"      => "a4703d",
    "burnt_sienna"  => "df8a3d",
    "orange"        => "e9b84e",
    "pea"           => "84bd37",
    "leaf"          => "409938",
    "spruce"        => "307355",
    "slate"         => "6c7a80",
    "silver"        => "a2a38b" )

  # These are the tags available for each change in Release Notes
  change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
               {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
               {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}} )

  # These are the types of tickets
  ticket_types(
    "Chore"       => "909090",
    "Feature"     => "8DB500",
    "Enhancement" => "3383A8",
    "Bug"         => "C64537" )



  # General
  # ---------------------------------------------------------------------------
  #
  # (Optional) Sets Time.zone and configures Active Record to auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  # time_zone "Central Time (US & Canada)"

  # (Optional) Parallelize requests.
  # Improves performance when Houston has to make several requests at once
  # to a remote API. Some firewalls might see this as suspicious activity.
  # In those environments, comment the following line out.
  parallelization :on

  # (Optional) Supply an S3 bucket to support file uploads
  s3 do
    access_key ENV["HOUSTON_S3_ACCESS_KEY"]
    secret ENV["HOUSTON_S3_SECRET"]
    bucket "houston-#{ENV["RAILS_ENV"] || "development"}"
  end

  # (Optional) These are the categories you can organize your projects by
  # project_categories "Products", "Services", "Libraries", "Tools"

  # (Optional) What dependencies to list on the Projects page
  # key_dependencies do
  #   gem "rails"
  #   gem "devise"
  # end

  # (Optional) Given a commit, return an array of email addresses
  # This is useful if your team uses pair-programming and attributes
  # commits to pairs by combining email addresses.
  # https://robots.thoughtbot.com/how-to-create-github-avatars-for-pairs
  identify_committers do |commit|
    emails = [commit.committer_email]
    emails = ["#{$1}@thoughtbot.com", "#{$2}@thoughtbot.com"] if commit.committer_email =~ /^([a-z\.]*)\+([a-z\.]*)@thoughtbot\.com/
    emails
  end



  # Navigation
  # ---------------------------------------------------------------------------
  #
  # Menus are provided by Houston and modules.
  # Additional navigation can be defined by calling
  #
  #   Houston.add_navigation_renderer
  #
  # For examples, see config/initializers/add_navigation_renderers.rb
  #
  # These are the menu items that will be shown in Houston
  navigation       :alerts,
                   :sprint
  project_features :tickets,
                   :testing,
                   :releases



  # Modules
  # ---------------------------------------------------------------------------
  #
  # Modules provide a way to extend Houston.
  #
  # They are mountable Rails Engines whose routes are automatically
  # added to Houston's, prefixed with the name of the module.
  #
  # To create a new module for Houston, run:
  #
  #   gem install houston-cli
  #   houston_new_module <MODULE>
  #
  # Then add the module to your Gemfile with:
  #
  #   gem "houston-<MODULE>", github: "<USERNAME>/houston-<MODULE>", branch: "master"
  #
  # Add add to this configuration file:
  #
  #   use :<MODULE> do
  #     # Module-supplied configuration options can go here
  #   end
  #
  # When developing a module, it can be helpful to tell Bundler
  # to refer to the local copy of your module's repo:
  #
  #   bundle config local.houston-<MODULE> ~/Projects/houston-<MODULE>
  #

  use :feedback
  use :roadmaps

  use :alerts do

    # Who can be assigned an Alert?
    workers { User.unretired }

    # Set a target-time for the Alert to be closed.
    # This block sets a goal of closing alerts within
    # 2 business days.
    set_deadline do |alert|
      time_allowed = 2.days
      if weekend?(alert.opened_at)
        time_allowed.after(monday_after(alert.opened_at))
      else
        deadline = time_allowed.after(alert.opened_at)
        deadline = 2.days.after(deadline) if weekend?(deadline)
        deadline
      end
    end
  end
  load "alerts/*"

  use :slack do
    token ENV["HOUSTON_SLACK_TOKEN"]
    typing_speed 120 # characters/second
    listen_for(/^(hello|hey|hi),? @houston[\!\.]*$/i) { |e| e.reply "hello" }
  end
  load "conversations/**/*"




  # Roles and Abilities
  # ---------------------------------------------------------------------------
  #
  # Every user will have one Role. You can refer to a user's roles when you
  # define her abilities. Houston will add the role "Guest" to this list.
  # "Guest" is the default role.
  #
  # NOTE: Presently, Houston requires that "Tester" be one of these roles.

  roles "Developer",
        "Tester"

  # Users additionally have any number of project-specific roles. You can
  # refer to these as well when configuring abilities.
  #
  # NOTE: Presently, Houston requires that "Maintainer" be one of these.

  project_roles "Maintainer",
                "Owner"

  # Houston uses CanCan to check authorize users to do particular actions.
  # Houston will pass a user to the block defined below which should declare
  # what abilities that user has.

  load "abilities"



  # Integrations
  # ---------------------------------------------------------------------------
  #
  # Configure Houston to integrate with third-party services

  load "integrations/*"



  # Events
  # ---------------------------------------------------------------------------
  #
  # Configure Houston to execute block of code when an event is triggered.
  # To see a complete list of events run `rake houston:events` at the command line.

  load "events/**/*"



  # Timers
  # ---------------------------------------------------------------------------
  #
  # Houston can be configured to run jobs at a variety of intervals.

  load "timers/**/*"



  # Perform any other initialization
  load "initializers/*"
end
