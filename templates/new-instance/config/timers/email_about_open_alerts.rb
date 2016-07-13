Houston.config.at "6:40am", "report:alerts", every: :weekday do
  Houston.try({max_tries: 3}, Net::OpenTimeout) do
    Houston::Alerts::Mailer.deliver_to!(FULL_TIME_DEVELOPERS) unless Rails.env.development?
  end
end
