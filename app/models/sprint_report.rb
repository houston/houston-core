class SprintReport
  attr_reader :user, :start_date, :end_date

  def initialize(user, start_date, end_date)
    @user = user
    @start_date = start_date
    @end_date = end_date
  end

  def to_json
    to_a.to_json
  end

  def to_a
    User.connection.select_rows(<<-SQL)
      SELECT
        sprints.end_date,
        SUM(completed.effort),
        SUM(checked_out.effort)
      FROM sprints

      LEFT OUTER JOIN (
        SELECT
          sprints_tasks.sprint_id,
          SUM(tasks.effort) "effort"
        FROM sprints_tasks
        INNER JOIN tasks ON sprints_tasks.task_id=tasks.id
        INNER JOIN sprints ON sprints_tasks.sprint_id=sprints.id
        WHERE COALESCE(tasks.first_commit_at, tasks.completed_at) BETWEEN sprints.end_date - interval '6 days' AND sprints.end_date + interval '1 day'
        #{"AND sprints_tasks.checked_out_by_id=#{user.id}" if user}
        GROUP BY sprints_tasks.sprint_id
      ) AS completed
        ON completed.sprint_id=sprints.id

      LEFT OUTER JOIN (
        SELECT
          sprints_tasks.sprint_id,
          SUM(tasks.effort) "effort"
        FROM sprints_tasks
        INNER JOIN tasks ON sprints_tasks.task_id=tasks.id
        #{"WHERE sprints_tasks.checked_out_by_id=#{user.id}" if user}
        GROUP BY sprints_tasks.sprint_id
      ) AS checked_out
        ON checked_out.sprint_id=sprints.id

      WHERE sprints.end_date BETWEEN '#{start_date.strftime "%Y-%m-%d"}' AND '#{end_date.strftime "%Y-%m-%d"}'
      GROUP BY sprints.end_date
      ORDER BY sprints.end_date ASC
    SQL
      .map { |(date, completed, checked_out)|
        [ date.to_date,
          completed.to_f,
          checked_out.to_f - completed.to_f ] }
  end

end
