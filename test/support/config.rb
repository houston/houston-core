Houston.config do
  host "houston.test.com"
  mailer_sender "houston@test.com"

  # TODO: without ticket_types configured, tests that cover them should be skipped
  ticket_types({
    "Chore"       => "909090",
    "Feature"     => "8DB500",
    "Enhancement" => "3383A8",
    "Bug"         => "C64537"
  })

  # TODO: without errbit configured, tests that cover them should be skipped
  error_tracker :errbit do
    host "errbit.example.com"
    auth_token "ERRBIT_AUTH_TOKEN"
  end
end
