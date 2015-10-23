# If you use Errbit, you can pull exception reports in as Alerts.

# The first time we sync errs after booting, we'll catch up
# by pulling down changes from the last week.
$errbit_since_changes_since = 1.week.ago

Houston::Alerts.config.sync :changes, "err", every: "45s" do
  app_project_map = Hash[Project
    .where(error_tracker_name: "Errbit")
    .pluck("(extended_attributes->'errbit_app_id')::integer", :id)]
  app_ids = app_project_map.keys

  Houston::Adapters::ErrorTracker::ErrbitAdapter.changed_problems(app_id: app_ids, since: $errbit_since_changes_since).map { |problem|
    key = "#{problem.id}-#{problem.opened_at.to_i}"
    { key: key,
      number: problem.err_ids.min,
      project_id: app_project_map[problem.app_id],
      summary: problem.message,
      environment_name: problem.environment,
      text: problem.where,
      opened_at: problem.opened_at,
      closed_at: problem.resolved_at,
      destroyed_at: problem.deleted_at,
      url: problem.url } }.tap do

    # From now on, we should expect to sync every 45 seconds,
    # so we'll pull down changes from a smaller window.
    $errbit_since_changes_since = 3.minutes.ago
  end
end
