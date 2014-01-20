Houston.config do
  
  # This is the name that will be shown in the banner
  title "Mission Control"
  
  # This is the host where Houston will be running
  host "houston.my-company.com"
  
  # This is the email address for emails send from Houston
  mailer_sender "houston@my-company.com"
  
  # This is the passphrase Houston will use to encrypt and decrypt sensitive data
  passphrase "SECRET"
  
  # Configuration for Email
  smtp do
    address "10.10.10.10"
    port 25
    domain "10.10.10.10"
  end
  
  # (Optional) These are the categories you can organize your projects by
  project_categories "Products", "Infrastructure", "Tools"
  
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
    "pea"           => "8dc63f",
    "leaf"          => "409938",
    "spruce"        => "307355",
    "slate"         => "6c7a80",
    "silver"        => "a2a38b" )
  
  # These are the environments you deploy projects to
  environments "Production", "Staging"
  
  
  
  # Roles:
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
        "Tester",
        "Mixer"
  
  # Project Roles:
  # Each of these roles is project-specific. A user
  # can have zero or many project roles. You can refer
  # to these roles when you configure abilities.
  #
  # Presently, Houston requires that "Maintainer" be
  # one of these roles.
  project_roles "Owner",
                "Maintainer"
  
  
  
  # Abilities:
  # In this block, use the DSL defined by CanCan.
  # Learn more: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  abilities do |user|
    if user.nil?
      
      # Customers are allowed to see Release Notes of products, for production
      can :read, Release do |release|
        release.project.category == "Products" && (release.environment_name.blank? || release.environment_name == "Production")
      end
      
      # Customers are allowed to see Features, Improvements, and Bugfixes
      can :read, Change, tag_slug: %w{feature improvement fix}
      
    else
      
      # Everyone can see Releases to staging
      can :read, Release
      
      # Everyone is allowed to see Features, Improvements, and Bugfixes
      can :read, Change, tag_slug: %w{feature improvement fix}
      
      # Everyone can see Projects
      can :read, Project
      
      # Everyone can see Tickets
      can :read, Ticket
      
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
      
      # Mixers can manage project quotas
      can :manage, Houston::Scheduler::ProjectQuota if user.mixer?
      
      # Developers see the other kinds of changes: Test Fixes and Refactors
      # as well as commit info
      can :read, [Commit, Change] if user.developer?
      
      # Mixers can see all testing notes
      can :read, TestingNote if user.mixer?
      
      
      
      # The following abilities are project-specific and depend on one's role
      
      roles = user.roles.participants
      if roles.any?
        
        # Everyone can see and comment on Testing Reports for projects they are involved in
        can [:create, :read], TestingNote, project_id: roles.pluck(:project_id)
        
        # Maintainers can manages Releases and update Projects
        can :manage, Release, project_id: roles.maintainers.pluck(:project_id)
        can :update, Project, id: roles.maintainers.pluck(:project_id)
        
        # With regard to Houston::Scheduler, Maintainers can write estimates;
        # while Product Owners can prioritize tickets.
        can :estimate, Project, id: roles.maintainers.pluck(:project_id)
        can :prioritize, Project, id: roles.owners.pluck(:project_id)
        
      end
    end
  end
  
  
  
  
  # The ticketing system that Houston will interface with.
  # Right now, the only supported system is Unfuddle.
  ticket_tracker :unfuddle do
    subdomain SUBDOMAIN
    username USERNAME
    password PASSWORD
  end
  
  
  
  # The CI server that Houston will interface with.
  # Right now, the only supported system is Jenkins.
  ci_server :jenkins do
    host HOSTNAME
    username USERNAME # (optional)
    password PASSWORD # (optional)
  end
  
  
  
  # The error-catching system that Houston will interface with.
  # Right now, the only supported system is Errbit.
  error_tracker :errbit do
    host HOST
    port 443
    auth_token TOKEN
  end
  
  
  
  # Configuration for New Relic
  new_relic do
    api_key API_KEY
    account_id ACCOUNT_ID
  end
  
  
  
  # What dependencies to check
  key_dependencies do
    gem "rails"
    gem "devise"
    gem "backbone-rails", as: "Backbone.js"
    gem "jquery-rails", as: "jQuery"
  end
  
  
  
  # List of ticket severities and their colors
  severities({
    nil                             => "EFEFEF",
    "0 Suggestion"                  => "92C4AD",
    "D Development"                 => "3FC1AA",
    "R Refactor"                    => "98C221",
    "1 Lack of Polish"              => "EBD94B",
    "1 Visual Bug"                  => "EBD94B",
    "P Performance"                 => "EBD94B",
    "2 Confusing to Users"          => "E9A43F",
    "3 Design Flaw"                 => "E9A43F",
    "4 Broken (with work-around)"   => "D65B17",
    "S Security Hole"               => "D65B17",
    "5 Broken (no work-around)"     => "C1311E"
  })
  
  
  
  # Queues
  # NB: because query is a hash, cannot use a key twice! (as in status-neq-closed & status-neq-resolved)
  queues [ {
      name: "To Proofread",
      slug: "assign_health",
      description: "Make sure these tickets are healthy, unique, and that you can reproduce the problem with the supplied Steps to Test.",
      query: {status: neq(:closed), resolution: 0, "Health" => 0}
    }, {
      name: "To Improve",
      slug: "to_fix",
      description: "These tickets do not contain enough information. Follow up with the reporter and see that they are clarified.",
      query: {status: neq(:closed), resolution: 0, "Health" => ["Summary and Description need work", "Summary needs work"]}
    }, {
      name: "To Consider",
      slug: "suggestions",
      description: "These tickets may or may not belong to the vision of this product. Consider them as a team and close them or change their severity.",
      query: {status: neq(:closed), resolution: 0, "Health" => ["Good", "Description needs work"], :milestone => [neq(:next_upcoming), 0], severity: "0 Suggestion"}
    }, {
      name: "Backlog",
      slug: "to_do",
      description: "This is the project backlog: open tickets that aren't up next.",
      query: {status: neq(:closed), resolution: 0, "Health" => ["Good", "Description needs work"], :milestone => [neq(:next_upcoming), 0], severity: neq("0 Suggestion")}
    }, {
      name: "Next Up",
      slug: "assigned_tickets",
      description: "These are open tickets that are scheduled for the next upcoming milestone.",
      query: [[:status, neq(:closed)], [:resolution, 0], ["Health", ["Good", "Description needs work"]], [:milestone, :next_upcoming], [:milestone, neq(0)]]
    }, {
      name: "Queued",
      slug: "staged_for_testing",
      description: "These tickets have been resolved, but are waiting for the current batch to be released before they enter testing.",
      query: {status: neq(:closed), resolution: :fixed, "Fixed in" => 0}
    }, {
      name: "To Test",
      slug: "in_testing",
      description: "These tickets are ready to test. Click on <b>Testing Reports</b> to record your testing notes.",
      query: {status: neq(:closed), resolution: :fixed, "Fixed in" => ["Staging", "Production"]}
  } ]
  
  
  
  # Callbacks
  # on "release:create" do |release|
  # end
  # 
  # on "testing_note:create" do |testing_note|
  # end
  # 
  # on "boot" do
  # end
  
  
  
  on "testing_note:create" do |testing_note|
    ticket = testing_note.ticket
    ProjectNotification.testing_note(testing_note).deliver! if ticket.participants.any?
  end
  
  on "deploy:create" do |deploy|
    deploy.project.maintainers.each do |maintainer|
      ProjectNotification.maintainer_of_deploy(maintainer, deploy).deliver!
    end
  end
  
  
  
  # Cron jobs
  cron do
    # In this block, use the DSL defined by the Whenever gem.
    # Learn more: http://github.com/javan/whenever
    
    # RECIPIENTS = %w{...}
    # 
    # every :monday, :at => "6am" do
    #   runner "WeeklyReport.deliver_to!(#{RECIPIENTS.inspect})"
    # end
    
    every :day, :at => "6:30am" do
      runner 'DailyReport.deliver_all!', environment: "production"
    end
    
  end
  
  
  
end
