Houston.config do
  
  # This is the name that will be shown in the banner
  title "Mission Control"
  
  # This is the host where Houston will be running
  host "houston.example.com"
  
  # This is the email address Houston will send emails from by default
  mailer_sender "houston@cphepdev.com"
  
  # (Optional) These are the categories you can organize your projects by
  project_categories "Products", "Tools"
  
  
  
  # These are the environments you deploy projects to
  environments "Staging", "Production"
  
  
  
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
  
  
  
  
  
  # The ticketing system that Houston will interface with.
  # Right now, the only supported system is Unfuddle.
  ticket_tracker :unfuddle do
    subdomain "cphep"
    
    identify_antecedents lambda { |ticket|
      goldmine_numbers = ticket.get_custom_value("Goldmine") || ""
      
      antecedents = []
      antecedents.concat goldmine_numbers.split(/[, ]/).map(&:strip).reject(&:blank?).map { |number| "Goldmine:#{number}" }
      antecedents.concat ticket.description.to_s.scan(/^Goldmine: (\d+)/).flatten.map { |number| "Goldmine:#{number}" }
      antecedents.concat ticket.description.to_s.scan(/^Errbit: ([0-9a-fA-F]+)/).flatten.map { |number| "Errbit:#{number}" }
      
      antecedents
    }
    
    # ticket.severity ? [ticket.severity.gsub(/^[\s\w] /, "")] : []
    
    identify_tags lambda { |ticket|
      [ticket.severity].compact
    }
    
    identify_type lambda { |ticket|
      case ticket.severity
      when nil                                                          then nil
      when "0 Suggestion", "D Development"                              then "Feature"
      when "1 Lack of Polish", "P Performance", "2 Confusing to Users"  then "Tweak"
      when "R Refactor"                                                 then "Chore"
      else                                                                   "Bug"
      end
    }
  end
  
  
  
  # Configure the Github Issues TicketTracker adapter
  ticket_tracker :github do
    identify_type lambda { |ticket|
      labels = ticket.raw_attributes.fetch("labels", []).map { |label| label["name"].downcase }
      return "Bug"      if (labels & %w{bug}).any?
      return "Feature"  if (labels & %w{feature enhancement}).any?
      return "Chore"    if (labels & %w{refactor}).any?
      nil
    }
  end
  
  
  
  # The CI server that Houston will interface with.
  # Right now, the only supported system is Jenkins.
  ci_server :jenkins do
    host "jenkins.example.com"
  end
  
  
  
  # The error-catching system that Houston will interface with.
  # Right now, the only supported system is Errbit.
  error_tracker :errbit do
    host "errbit.example.com"
    port 443
    auth_token "TOKEN"
  end
  
  
  
  # Configuration for New Relic
  # new_relic do
  #   api_key API_KEY
  #   account_id ACCOUNT_ID
  # end
  
  
  
  # Configuration for GitHub
  # Use the following command to generate an access_token
  # for your GitHub account to allow Houston to modify
  # commit statuses.
  #
  # curl -v -u USERNAME -X POST https://api.github.com/authorizations --data '{"scopes":["repo:status"]}'
  #
  github do
    access_token "accesstoken"
  end
  
  
  
  # What dependencies to check
  key_dependencies do
    gem "rails", ["3.2.13", "3.1.12"]
    gem "devise", ["2.2.3", "2.1.3", "2.0.5", "1.5.4"]
  end
  
  
  
  # Configuration for Email
  # smtp do
  #   address "10.10.10.10"
  #   port 25
  #   domain "10.10.10.10"
  # end
  
  
  
  # Colors: these are the colors available for projects
  project_colors({
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
    "silver"        => "a2a38b"
  })
  
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
  
  # Tags: these are the tags available for Change Log entries
  change_tags([
    {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}},
    {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
    {name: "New Feature", as: "feature", color: "8DB500"},
    {name: "Refactor", as: "refactor", color: "909090"},
    {name: "Testfix", as: "testfix", color: "909090"},
    {name: "CI Fix", as: "ci", color: "909090", aliases: %w{cifix ciskip}}
  ])
  
  
  
  # Queues
  queues do
    unprioritized do
      name "To Prioritize"
      description "Tickets for <b>Product Owners</b> to prioritize"
      where { |tickets| tickets.unresolved.unprioritized }
    end
    
    unestimated do
      name "To Estimate"
      description "Tickets for <b>Developers</b> to estimate"
      where { |tickets| tickets.unresolved.unestimated }
    end
    
    sprint do
      name "Sprint"
      description "Tickets left in the current sprint"
      where { |tickets| tickets.unresolved.in_current_sprint }
    end
    
    testing do
      name "To Test"
      description "Tickets for <b>Testers</b> to test"
      where { |tickets| tickets.resolved.open.deployed }
    end
    
    staging do
      name "To Release"
      description "Tickets ready for <b>Maintainers</b> to deploy"
      where { |tickets| tickets.closed.deployed_to("Staging") }
    end
  end
  
  
  
  # Modules
  # use :scheduler, :git => "git://github.com/houstonmc/houston-scheduler.git"
  
  
  
  # Cron jobs
  # cron do
  #   # In this block, use the DSL defined by the Whenever gem.
  #   # Learn more: http://github.com/javan/whenever
  #   
  #   every :monday, :at => "6am" do
  #     runner "WeeklyReport.new(1.week.ago).deliver_to!(#{RECIPIENTS.inspect})", environment: "production"
  #   end
  #   
  # end
  
  
  
end
