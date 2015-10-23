Houston.config do
  on "alert:assign" do |alert|
    if alert.checked_out_by && alert.updated_by && alert.checked_out_by != alert.updated_by
      Rails.logger.info "\e[34m[slack] #{alert.type} assigned to \e[1m#{alert.checked_out_by.first_name}\e[0m"

      case (rand * 100).to_i
      when 0..3
        message = ":bomb:"
      when 4..25
        message = "#{alert.updated_by.first_name} threw you under the bus"
      when 26..70
        message = "#{alert.checked_out_by.first_name}, #{alert.updated_by.first_name} assigned you this *#{alert.type}*"
        message << " for #{alert.project.slug}" if alert.project
      else
        message = "#{alert.checked_out_by.first_name}, #{alert.updated_by.first_name} assigned this *#{alert.type}*"
        message << " for #{alert.project.slug}" if alert.project
        message << " to you"
      end

      slack_send_message_to message, alert.checked_out_by, attachments: [slack_alert_attachment(alert)]
    end
  end
end
