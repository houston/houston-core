Houston.config do
  host "houston.test.com"
  mailer_sender "houston@test.com"

  role "Developer" do |team|
    can :manage, Sprint
  end

  # TODO: without ticket_types configured, tests that cover them should be skipped
  ticket_types({
    "Chore"       => "909090",
    "Feature"     => "8DB500",
    "Enhancement" => "3383A8",
    "Bug"         => "C64537"
  })

  # TODO: without these configured, the New Release acceptance test should be skipped
  change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
               {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
               {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}} )

  # TODO: without jenkins configured, tests that cover them should be skipped
  ci_server :jenkins do
    host "jenkins.example.com"
  end

  # TODO: without errbit configured, tests that cover them should be skipped
  error_tracker :errbit do
    host "errbit.example.com"
    auth_token "ERRBIT_AUTH_TOKEN"
  end
end
