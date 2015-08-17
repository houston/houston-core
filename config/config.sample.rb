Houston.config do

  # This is the name that will be shown in the banner
  title "Houston"

  # This is the host where Houston will be running
  host "houston.my-company.com"

  # This is the email address for emails send from Houston
  mailer_sender "houston@my-company.com"

  # This is the passphrase Houston will use to encrypt and decrypt sensitive data
  passphrase "Keep it secret! Keep it safe."

  # Parallelize requests.
  # Improves performance when Houston has to make several requests at once
  # to a remote API. Some firewalls might see this as suspicious activity.
  # In those environments, comment the following line out.
  parallelization :on

  # Configuration for Email
  smtp do
    address "10.10.10.10"
    port 25
    domain "10.10.10.10"
  end

  # (Optional) Supply an S3 bucket to support file uploads
  # s3 do
  #   access_key ACCESS_KEY
  #   secret SECRET
  #   bucket "houston-#{ENV["RAILS_ENV"] || "development"}"
  # end

  # (Optional) These are the categories you can organize your projects by
  project_categories "Products", "Services", "Libraries", "Tools"

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

  # These are the environments you deploy projects to
  environments "Production", "Staging"

  # These are the tags available for each change in Release Notes
  change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
               {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
               {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}},
               {name: "Refactor", as: "refactor", color: "909090"},
               {name: "Testfix", as: "testfix", color: "909090"},
               {name: "CI Fix", as: "ci", color: "909090", aliases: %w{cifix ciskip}} )

  # These are the types of tickets
  ticket_types({
    "Chore"       => "909090",
    "Feature"     => "8DB500",
    "Enhancement" => "3383A8",
    "Bug"         => "C64537"
  })



  # Navigation
  # ---------------------------------------------------------------------------
  # 
  # Menus are provided by Houston and modules.
  # Additional navigation can be defined by calling
  #
  #   Houston.config.add_navigation_renderer
  # 
  # For examples, see config/initializers/add_navigation_renderers.rb
  #
  # These are the menu items that will be shown in Houston
  navigation       :alerts,
                   :roadmap,
                   :sprint
  project_features :feedback,
                   :ideas,
                   :bugs,
                   :scheduler,
                   :roadmap,
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
  # Then add the module to this file with:
  #
  #   use :<MODULE>, github: "<USERNAME>/houston-<MODULE>", branch: "master"
  #
  # When developing a module, it can be helpful to tell Bundler
  # to refer to the local copy of your module's repo:
  #
  #   bundle config local.houston-<MODULE> ~/Projects/houston-<MODULE>
  #

  use :roadmap, github: "houston/houston-roadmap", branch: "master"

  use :alerts, github: "houston/houston-alerts", branch: "master" do
    workers { User.developers }

    sync :all, "ue", every: "75s", first_in: "15s" do
      app_project_map = Hash[Project
        .where(error_tracker_name: "Errbit")
        .pluck("cast(extended_attributes->'errbit_app_id' as integer)", :id)]

      Houston::Adapters::ErrorTracker::ErrbitAdapter \
        .all_problems(app_id: app_project_map.keys)
        .map { |problem|
          key = problem.id.to_s
          key << "-#{problem.opened_at.to_i}"
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
          { key: "#{alert["project_slug"]}-#{advisory["id"]}",
            project_slug: alert["project_slug"],
            summary: advisory["title"],
            url: "https://gemnasium.com/#{alert["project_id"]}/alerts#advisory_#{advisory["id"]}"
          } }
    end
  end

  use :feedback, github: "houston/houston-feedback", branch: "master"

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


  # use :scheduler, github: "houston/houston-scheduler", branch: "master" do
  #   planning_poker :off
  #   estimate_effort :off
  #   estimate_value :off
  #   mixer :off
  # end





  # Roles
  # ---------------------------------------------------------------------------
  #
  # A user can have zero or one of these roles.
  # You can refer to these roles when you configure
  # abilities.
  #
  # To this list, Houston will add the role "Guest",
  # which is the default (null) role.
  #
  # Presently, Houston requires that "Tester" be
  # one of these roles.
  roles "Developer",
        "Tester"

  # Project Roles
  # ---------------------------------------------------------------------------
  #
  # Each of these roles is project-specific. A user
  # can have zero or many project roles. You can refer
  # to these roles when you configure abilities.
  #
  # Presently, Houston requires that "Maintainer" be
  # one of these roles.
  project_roles "Owner",
                "Maintainer"

  # Abilities
  # ---------------------------------------------------------------------------
  #
  # In this block, use the DSL defined by CanCan.
  # Learn more: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  abilities do |user|
    if user.nil?

      # Customers are allowed to see Release Notes of products, for production
      can :read, Release do |release|
        release.project.category == "Products" && (release.environment_name.blank? || release.environment_name == "Production")
      end

      # Customers are allowed to see Features, Improvements, and Bugfixes
      can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

    else

      # Everyone can see Releases to staging
      can :read, Release

      # Everyone is allowed to see Features, Improvements, and Bugfixes
      can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

      # Everyone can see Projects
      can :read, Project

      # Everyone can see and create Tickets
      can [:read, :create], Ticket

      # Everyone can see Milestones
      can :read, Milestone

      # Everyone can see Users and update themselves
      can :read, User
      can :update, user

      # Everyone can make themselves a "Follower"
      can :create, Role, name: "Follower"

      # Everyone can remove themselves from a role
      can :destroy, Role, user_id: user.id

      # Everyone can edit their own testing notes
      can [:update, :destroy], TestingNote, user_id: user.id

      # Everyone can see project quotas
      can :read, Houston::Scheduler::ProjectQuota

      # Everyone can read and tag and create feedback
      can :read, Houston::Feedback::Comment
      can :tag, Houston::Feedback::Comment
      can :create, Houston::Feedback::Comment

      # Everyone can update their own feedback
      can [:update, :destroy], Houston::Feedback::Comment, user_id: user.id

      # Developers can
      #  - see other kinds of Release Changes (like Refactors)
      #  - update Sprints
      #  - change Milestones' tickets
      #  - break tickets into tasks
      if user.developer?
        can :read, [Commit, ReleaseChange]
        can :manage, Sprint
        can :update_tickets, Milestone
        can :manage, Task
      end

      # Testers and Developers can see and comment on all testing notes
      can [:create, :read], TestingNote if user.tester? or user.developer?
      
      # Testers and Developers can see and manage alerts
      can :manage, Houston::Alerts::Alert if user.developer? or user.tester?

      # The following abilities are project-specific and depend on one's role
      roles = user.roles.participants
      if roles.any?

        # Everyone can see and comment on Testing Reports for projects they are involved in
        can [:create, :read], TestingNote, project_id: roles.pluck(:project_id)

        # Maintainers can manage Releases, close and estimate Tickets, and update Projects
        roles.maintainers.pluck(:project_id).tap do |project_ids|
          can :manage, Release, project_id: project_ids
          can :update, Project, id: project_ids
          can :close, Ticket, project_id: project_ids
          can :estimate, Project, id: project_ids # <-- !todo: remove
        end

        # Product Owners can prioritize tickets
        can :prioritize, Project, id: roles.owners.pluck(:project_id)
      end
    end
  end



  # Integrations
  # ---------------------------------------------------------------------------
  #
  # Configure Houston to integrate with third-party services

  # (Optional) Utilize an alternate Devise Authentication Strategy
  # authentication_strategy :ldap do
  #   host "10.10.10.10"
  #   port 636
  #   base "ou=people,dc=example,dc=com"
  #   ssl :simple_tls
  #   username_builder Proc.new { |attribute, login, ldap| "#{login}@example.com" }
  # end

  # Configure the Unfuddle TicketTracker adapter
  # ticket_tracker :unfuddle do
  #   subdomain "UNFUDDLE_SUBDOMAIN"
  #   username "UNFUDDLE_USERNAME"
  #   password "UNFUDDLE_PASSWORD"
  #   
  #   identify_tags lambda { |ticket|
  #     # ...
  #   }
  #   
  #   identify_type lambda { |ticket|
  #     # ...
  #   }
  #   
  #   attributes_from_type lambda { |ticket|
  #     # ...
  #   }
  # end

  # Configure the Github Issues TicketTracker adapter
  # ticket_tracker :github do
  #   identify_tags lambda { |ticket|
  #     # ...
  #   }
  #   
  #   identify_type lambda { |ticket|
  #     # ...
  #   }
  #   
  #   attributes_from_type lambda { |ticket|
  #     # ...
  #   }
  # end

  # Configure the Jenkins CIServer adapter
  # ci_server :jenkins do
  #   host "jenkins.example.com"
  #   username "JENKINS_USERNAME"
  #   password "JENKINS_PASSWORD"
  # end

  # Configure the Errbit ErrorTracker adapter
  # error_tracker :errbit do
  #   host "errbit.example.com"
  #   port 443
  #   auth_token "ERRBIT_AUTH_TOKEN"
  # end

  # Configuration for GitHub
  # Use the following command to generate an access_token
  # for your GitHub account to allow Houston to modify
  # commit statuses.
  #
  # curl -v -u USERNAME -X POST https://api.github.com/authorizations --data '{"scopes":["repo:status"]}'
  #
  # github do
  #   access_token "GITHUB_ACCESS_TOKEN"
  #   key "GITHUB_OAUTH_KEY"
  #   secret "GITHUB_OAUTH_SECRET"
  #   
  #   # If you specify a GitHub organization, Houston can
  #   # grab Pull Requests for that organization and put them
  #   # into your To-Do Lists.
  #   # organization "GITHUB_ORGANIZATION"
  # end

  # Configuration for Gemnasium
  # gemnasium do
  #   api_key "GEMNASIUM_API_KEY"
  # end



  # Events
  # ---------------------------------------------------------------------------
  #
  # Attach a block to handle any of the events broadcast by
  # Houston's event system:
  #   * antecedent:*:released   When a Ticket has been released, for each antecedent
  #   * antecedent:*:resolved   When a Ticket has been resolved, for each antecedent
  #   * antecedent:*:closed     When a Ticket has been closed, for each antecedent
  #   * boot                    When the Rails application is booted
  #   * scheduler:shutdown      When the scheduler thread (for Background Jobs) dies
  #   * deploy:completed           When a deploy has been recorded
  #   * hooks:*                 When a Web Hook as been triggered
  #   * release:create          When a new Release has been created
  #   * test_run:start          When the CI server has begun a build
  #   * test_run:complete       When the CI server has completed a build
  #   * testing_note:create     When a Testing Note has been created
  #   * testing_note:update     When a Testing Note has been updated
  #   * testing_note:save       When a Testing Note has been created or updated
  #   * ticket:release          When a Ticket is mentioned in a Release
  #   * task:released           When a commit mentioning a Task is released
  #   * task:committed          When a commit mentioning a Task is pushed
  #   * task:completed          When a Task is marked completed
  #   * task:reopened           When a Task is marked reopened
  #   * alert:create            When an Alert is created
  #   * alert:*:create          When an Alert of a particular type is created
  #   * alert:assign            When an Alert is assigned

  # on "boot" do
  #   Airbrake.configure do |config|
  #     config.api_key          = AIRBRAKE_API_KEY
  #   end
  # end

  on "task:committed" do |task|
    # Treat tasks as completed when a commit mentioning them is pushed
    task.completed!
  end

  # on "alert:assign" do |alert|
  #   EXAMPLE
  #   Put code here to notify the developer who
  #   has been assigned the alert via Slack or Campfire.
  # end

  # on "alert:create" do |alert|
  #   EXAMPLE
  #   Put code here to assign the alert to a developer
  #   based on the alert's project or content.
  # end

  on "deploy:completed" do |deploy|
    if deploy.project.error_tracker_name == "Errbit"
      errbit, repo = deploy.project.error_tracker, deploy.project.repo
      deploy.commits.each do |commit|
        commit.antecedents.each do |antecedent|
          next unless antecedent.kind == "Errbit"
          
          message = "Resolved by Houston when #{commit.sha} was deployed to #{deploy.environment_name}"
          message << "\n#{repo.commit_url(commit.sha)}" if repo.respond_to?(:commit_url)
          begin
            errbit.resolve! antecedent.id, message: message
          rescue Faraday::Error::ResourceNotFound
            # Ignore missing antecedents
          end
        end
      end
    end
  end

  # on "testing_note:create" do |testing_note|
  #   play "failing-verdict" if testing_note.first_fail?
  # end

  # on "test_run:complete" do |test_run|
  #   play "build-broken" if test_run.broken?
  #   play "build-fixed" if test_run.fixed?
  # end

  # on "deploy:completed" do |deploy|
  #   if deploy.project.category == "Tools"
  #     play "release-tool"
  #   else
  #     play "release-#{deploy.environment_name.downcase}"
  #   end
  # end

  # on "hooks:exception_report" do
  #   play "exception"
  # end



  # Background Jobs
  # ---------------------------------------------------------------------------
  #
  # Houston can be configured to run jobs at a variety of intervals.

  every "6h", "sync:tickets" do
    SyncAllTicketsJob.run!
  end

  at "2:00am", "sync:commits" do
    SyncCommitsJob.run!
  end

  at "6:40am", "report:alerts", every: :weekday do
    Houston::Alerts::Mailer.deliver_to!(User.pluck(:email))
  end

  at "11:50pm", "take:measurements", every: :thursday do
    take_measurements! Time.now
  end



  # Other
  # ---------------------------------------------------------------------------

  # Should return an array of email addresses
  identify_committers do |commit|
    [commit.committer_email]
  end

  # When a ticket's description is updated, this block
  # allows you to parse the description and set additional
  # properties
  # parse_ticket_description do |ticket|
  #   This block is invoked whenever a ticket's description is changed,
  #   allowing you to parse its contents and trigger behavior when
  #   certain patterns are recognized.
  # end

  # What dependencies to check
  key_dependencies do
    gem "rails"
    gem "devise"
  end



end
