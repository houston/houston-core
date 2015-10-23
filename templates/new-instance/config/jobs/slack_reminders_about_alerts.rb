require "yaml/store"

Houston.config.every "2m", "remind:alerts" do
  store = YAML::Store.new("reminders.yml")

  threshold = 4.hours.from_now
  end_of_day = 16 # 4:00pm

  threshold += 16.hours if threshold.hour > end_of_day # is it afternoon? see what alerts are due in the morning.
  threshold += 1.day if threshold.wday == 6 # advance Saturday to Sunday
  threshold += 1.day if threshold.wday == 0 # advance Sunday to Monday
  alerts_coming_due = Houston::Alerts::Alert.open.checked_out.due_before(threshold)

  reminders = alerts_coming_due.pluck(:id, :checked_out_by_id).map { |ids| ids.join("-") }
  reminders_sent = store.transaction { store[:reminders_sent] } || []
  reminders_sent &= reminders # prune reminders for closed or late Alerts
  reminders_needed = reminders - reminders_sent

  # reminders_needed will be an array of strings like /:alert_id-:user_id/
  # we can treat these like an array of IDs because when calling `:to_i`
  # on a string like that, Ruby will return everyting up to the hyphen:
  # that is, the Alert ID.
  Houston::Alerts::Alert.open.checked_out.where(id: reminders_needed).each do |alert|
    assignee = alert.checked_out_by
    seconds = alert.seconds_remaining
    next if seconds < 180 # Skip it if we're late or have less than 2 minutes

    Rails.logger.info "\e[34m[slack] reminding \e[1m#{assignee.first_name}\e[0;34m of alert due in \e[1m#{seconds}s\e[0m"

    message = "Hey #{assignee.first_name}, this *#{alert.type}*"
    message << " for #{alert.project.slug}" if alert.project

    due_date = alert.deadline.to_date
    if due_date == Date.today
      minutes = seconds / 60
      hours = minutes / 60
      minutes -= (hours * 60)

      # Round up to the next hour
      if minutes > 50
        minutes = 0
        hours += 1
      end

      if hours == 0
        timeleft = "#{minutes} minutes"
      elsif hours == 1
        timeleft = "1 hour"
        timeleft << " and #{minutes} minutes" if minutes >= 10
      else
        timeleft = "#{hours} hours"
        timeleft << " and #{minutes} minutes" if minutes >= 10
      end

      message << " is due in *#{timeleft}*"
    else
      date = due_date == Date.today + 1 ? "tomorrow" : due_date.strftime("%A")
      message << " is due *#{date} at #{alert.deadline.strftime("%-I:%M %P")}*"
    end

    slack_send_message_to message, assignee, attachments: [slack_alert_attachment(alert)]

    reminders_sent << "#{alert.id}-#{alert.checked_out_by_id}"
    store.transaction { store[:reminders_sent] = reminders_sent }
  end
end
