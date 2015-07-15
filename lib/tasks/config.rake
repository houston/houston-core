module ConfigSanitizer
  
  def replace_value!(name, value)
    gsub! /^  #{name} .*$/, "  #{name} #{value.inspect}"
  end
  
  def replace_block!(name, value, comment_out: false)
    value = value.rstrip
    if comment_out
      value = "  \# #{name}\\1do\\2\n#{value.gsub(/^  /, '  # ')}\n  \# end"
    else
      value = "  #{name}\\1do\\2\n#{value}\n  end"
    end
    gsub! /^  #{name}([^\n]+)do( \|[^\|]+\|)?\n.*?^  end/m, value
  end
  
  def remove!(text)
    gsub! text, ''
  end
  
  def insert_after!(regex, text)
    gsub! /(#{regex})/, "\\1\n#{text.chomp}"
  end
  
  def remove_block!(name)
    gsub! /^  #{name}[^\n]+do( \|[^\|]+\|)?\n.*?^  end\s*/m, '  '
  end
  
end

namespace :config do
  
  desc "Generate config.sample.rb from config.rb"
  task :generate do
    config = File.read Rails.root.join("config", "config.rb")
    config.extend ConfigSanitizer # Strip out sensitive information
    
    
    
    # GENERAL
    config.replace_value! :host, "houston.my-company.com"
    config.replace_value! :mailer_sender, "houston@my-company.com"
    config.replace_value! :passphrase, "Keep it secret! Keep it safe."
    config.replace_value! :parallelization, :on
    config.replace_block! :smtp, <<-TEXT
    address "10.10.10.10"
    port 25
    domain "10.10.10.10"
    TEXT
    config.replace_block! :s3, <<-TEXT, comment_out: true
    access_key ACCESS_KEY
    secret SECRET
    bucket "houston-\#{ENV["RAILS_ENV"] || "development"}"
    TEXT
    
    
    
    # MODULES
    config.replace_block! 'use :scheduler', <<-TEXT, comment_out: true
    planning_poker :off
    estimate_effort :off
    estimate_value :off
    mixer :off
    TEXT
    config.replace_block! 'use :alerts', <<-TEXT
    workers { User.developers }

    sync :all, "ue", every: "75s", first_in: "15s" do
      app_project_map = Hash[Project
        .where(error_tracker_name: "Errbit")
        .pluck("cast(extended_attributes->'errbit_app_id' as integer)", :id)]

      Houston::Adapters::ErrorTracker::ErrbitAdapter \\
        .all_problems(app_id: app_project_map.keys)
        .map { |problem|
          key = problem.id.to_s
          key << "-\#{problem.opened_at.to_i}"
          { key: key,
            project_id: app_project_map[problem.app_id],
            summary: problem.message,
            closed_at: problem.resolved_at,
            url: problem.url
          } }
    end

    sync :open, "cve", every: "5m", first_in: "30s" do
      Gemnasium::Alert.open
        .map { |alert|
          advisory = alert["advisory"]
          { key: "\#{alert["project_slug"]}-\#{advisory["id"]}",
            project_slug: alert["project_slug"],
            summary: advisory["title"],
            url: "https://gemnasium.com/\#{alert["project_id"]}/alerts#advisory_\#{advisory["id"]}"
          } }
    end
    TEXT
    config.insert_after! /^  use :itsm.*/, <<-TEXT
  # use :kanban, github: "houston/houston-kanban", branch: "master" do
  #   queues do
  #     unprioritized do
  #       name "To Prioritize"
  #       description "Tickets for <b>Product Owners</b> to prioritize"
  #       where { |tickets| tickets.unresolved.able_to_prioritize.unprioritized }
  #     end
  # 
  #     unestimated do
  #       name "To Estimate"
  #       description "Tickets for <b>Developers</b> to estimate"
  #       where { |tickets| tickets.unresolved.able_to_estimate.unestimated }
  #     end
  # 
  #     sprint do
  #       name "Sprint"
  #       description "Tickets left in the current sprint"
  #       where { |tickets| tickets.unresolved.in_current_sprint }
  #     end
  # 
  #     testing do
  #       name "To Test"
  #       description "Tickets for <b>Testers</b> to test"
  #       where { |tickets| tickets.resolved.open.deployed }
  #     end
  # 
  #     staging do
  #       name "To Release"
  #       description "Tickets ready for <b>Maintainers</b> to deploy"
  #       where { |tickets| tickets.closed.fixed.unreleased }
  #     end
  #   end
  # end
    TEXT
    config.remove! /^  use :itsm,[^\n]+\n/
    config.remove! /^  use :reports,[^\n]+\n/
    config.remove! /^  use :support_form,[^\n]+\n/
    config.remove! /^  gem "star",[^\n]+\n/
    
    
    
    # INTEGRATIONS
    config.replace_block! "authentication_strategy :ldap", <<-TEXT, comment_out: true
    host "10.10.10.10"
    port 636
    base "ou=people,dc=example,dc=com"
    ssl :simple_tls
    username_builder Proc.new { |attribute, login, ldap| "\#{login}@example.com" }
    TEXT
    config.replace_block! "ticket_tracker :unfuddle", <<-TEXT, comment_out: true
    subdomain "UNFUDDLE_SUBDOMAIN"
    username "UNFUDDLE_USERNAME"
    password "UNFUDDLE_PASSWORD"
    
    identify_tags lambda { |ticket|
      # ...
    }
    
    identify_type lambda { |ticket|
      # ...
    }
    
    attributes_from_type lambda { |ticket|
      # ...
    }
    TEXT
    config.replace_block! "ticket_tracker :github", <<-TEXT, comment_out: true
    identify_tags lambda { |ticket|
      # ...
    }
    
    identify_type lambda { |ticket|
      # ...
    }
    
    attributes_from_type lambda { |ticket|
      # ...
    }
    TEXT
    config.replace_block! "ci_server :jenkins", <<-TEXT, comment_out: true
    host "jenkins.example.com"
    username "JENKINS_USERNAME"
    password "JENKINS_PASSWORD"
    TEXT
    config.replace_block! "error_tracker :errbit", <<-TEXT, comment_out: true
    host "errbit.example.com"
    port 443
    auth_token "ERRBIT_AUTH_TOKEN"
    TEXT
    config.replace_block! "github", <<-TEXT, comment_out: true
    access_token "GITHUB_ACCESS_TOKEN"
    key "GITHUB_OAUTH_KEY"
    secret "GITHUB_OAUTH_SECRET"
    
    # If you specify a GitHub organization, Houston can
    # grab Pull Requests for that organization and put them
    # into your To-Do Lists.
    # organization "GITHUB_ORGANIZATION"
    TEXT
    config.replace_block! "gemnasium", <<-TEXT, comment_out: true
    api_key "GEMNASIUM_API_KEY"
    TEXT
    
    
    
    # EVENTS
    config.remove_block! 'on "deploy:completed"'
    config.remove_block! 'on "hooks:mailgun_complaint"'
    config.remove_block! 'on "testing_note:create"'
    config.remove_block! 'on "test_run:complete"'
    config.remove_block! 'on "ticket:release"'
    config.remove_block! 'on "scheduler:shutdown"'
    config.remove_block! 'on "alert:itsm:create"'
    config.replace_block! 'on "boot"', <<-TEXT, comment_out: true
    Airbrake.configure do |config|
      config.api_key          = AIRBRAKE_API_KEY
    end
    TEXT
    config.replace_block! 'on "alert:assign"', <<-TEXT, comment_out: true
    EXAMPLE
    Put code here to notify the developer who
    has been assigned the alert via Slack or Campfire.
    TEXT
    config.replace_block! 'on "alert:create"', <<-TEXT, comment_out: true
    EXAMPLE
    Put code here to assign the alert to a developer
    based on the alert's project or content.
    TEXT
    
    
    
    # BACKGROUND JOBS
    config.replace_block! 'at "6:40am", "report:alerts", every: :weekday', <<-TEXT
    Houston::Alerts::Mailer.deliver_to!(User.pluck(:email))
    TEXT
    config.replace_block! 'at "3:00pm", "report:pull-requests", every: :weekday', <<-TEXT
    PullRequestsMailer.deliver_to!(User.developers.pluck(:email))
    TEXT
    
    
    
    # OTHER
    config.replace_block! :identify_committers, <<-TEXT
    [commit.committer_email]
    TEXT
    config.replace_block! "parse_ticket_description", <<-TEXT, comment_out: true
    This block is invoked whenever a ticket's description is changed,
    allowing you to parse its contents and trigger behavior when
    certain patterns are recognized.
    TEXT
    
    
    
    # Remove all the globals and other stuff at the end of the config file
    config.gsub! /^end.*\Z/m, "end\n"
    
    File.open Rails.root.join("config", "config.sample.rb"), "w" do |f|
      f.write(config)
    end
  end
end
