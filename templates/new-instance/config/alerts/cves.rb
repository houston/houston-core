# If you use Gemnasium, you can pull CVE advisories in as Alerts.

require_relative "../../lib/gemnasium-alert"

Houston::Alerts.config.sync :open, "cve", every: "5m" do
  Gemnasium::Alert.open.map { |alert|
    advisory = alert["advisory"]
    { key: "#{alert["project_slug"]}-#{advisory["id"]}",
      number: advisory["id"],
      project_slug: alert["project_slug"],
      summary: advisory["title"],
      environment_name: "production",
      url: "https://gemnasium.com/#{alert["project_id"]}/alerts#advisory_#{advisory["id"]}" } }
end
