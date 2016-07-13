Houston.config do
  on "alert:assign" do |e|
    if e.alert.checked_out_by && e.alert.updated_by && e.alert.checked_out_by != e.alert.updated_by
      Rails.logger.info "\e[34m[slack] #{e.alert.type} assigned to \e[1m#{e.alert.checked_out_by.first_name}\e[0m"

      case (rand * 100).to_i
      when 0..3
        message = ":bomb:"
      when 4..25
        message = "#{e.alert.updated_by.first_name} threw you under the bus"
      when 26..70
        message = "#{e.alert.checked_out_by.first_name}, #{e.alert.updated_by.first_name} assigned you this *#{e.alert.type}*"
        message << " for #{e.alert.project.slug}" if e.alert.project
      else
        message = "#{e.alert.checked_out_by.first_name}, #{e.alert.updated_by.first_name} assigned this *#{e.alert.type}*"
        message << " for #{e.alert.project.slug}" if e.alert.project
        message << " to you"
      end

      slack_send_message_to message, e.alert.checked_out_by, attachments: [slack_alert_attachment(e.alert)]
    end
  end
end
