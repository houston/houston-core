module ConfigSanitizer
  
  def replace_value!(name, value)
    gsub! /^  #{name} .*$/, "  #{name} #{value.inspect}"
  end
  
  def replace_block!(name, value, comment_out: false)
    value = value.rstrip
    if comment_out
      value = "  \# #{name} do\\1\n#{value.gsub(/^  /, '  # ')}\n  \# end"
    else
      value = "  #{name} do\\1\n#{value}\n  end"
    end
    gsub! /^  #{name} do( \|[^\|]+\|)?\n.*?^  end/m, value
  end
  
  def remove!(text)
    gsub! text, ''
  end
  
  def remove_block!(name)
    gsub! /^  #{name} do( \|[^\|]+\|)?\n.*?^  end\s*/m, '  '
  end
  
end

namespace :config do
  
  desc "Generate config.sample.rb from config.rb"
  task :generate do
    config = File.read Rails.root.join("config", "config.rb")
    config.extend ConfigSanitizer
    
    # Strip out sensitive information
    config.replace_value! :host, "houston.my-company.com"
    config.replace_value! :mailer_sender, "houston@my-company.com"
    config.replace_value! :passphrase, "Keep it secret! Keep it safe."
    config.replace_value! :parallelization, :on
    config.replace_block! :smtp, <<-TEXT
    address "10.10.10.10"
    port 25
    domain "10.10.10.10"
    TEXT
    config.replace_block! :identify_committers, <<-TEXT
    [commit.committer_email]
    TEXT
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
    
    identify_antecedents lambda { |ticket|
      # ...
    }
    
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
    config.remove! /(  \n)+  # Configure the Github Issues TicketTracker adapter/m
    config.remove_block! "ticket_tracker :github"
    config.replace_block! "ci_server :jenkins", <<-TEXT
    host "jenkins.example.com"
    username "JENKINS_USERNAME"
    password "JENKINS_PASSWORD"
    TEXT
    config.replace_block! "error_tracker :errbit", <<-TEXT
    host "errbit.example.com"
    port 443
    auth_token "ERRBIT_AUTH_TOKEN"
    TEXT
    config.remove! /(  \n)+  # Configuration for New Relic/m
    config.remove_block! "new_relic"
    config.replace_block! "github", <<-TEXT
    access_token "GITHUB_ACCESS_TOKEN"
    key "GITHUB_OAUTH_KEY"
    secret "GITHUB_OAUTH_SECRET"
    
    # If you specify a GitHub organization, Houston can
    # grab Pull Requests for that organization and put them
    # into your To-Do Lists.
    # organization "GITHUB_ORGANIZATION"
    TEXT
    config.remove_block! 'on "deploy:create"'
    config.remove_block! 'on "hooks:exception_report"'
    config.remove_block! 'on "testing_note:create"'
    config.remove_block! 'on "test_run:complete"'
    config.remove_block! 'on "ticket:release"'
    config.remove_block! 'on "boot"'
    config.remove! /^  use :itsm,[^\n]+\n/
    
    config.gsub! /^end.*\Z/m, "end\n"
    
    File.open Rails.root.join("config", "config.sample.rb"), "w" do |f|
      f.write(config)
    end
  end
end
