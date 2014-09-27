class ReportsController < ApplicationController
  before_filter { authorize! :read, :reports }
  before_filter :find_tickets, only: [:queue_age, :cycle_time, :time_to_first_test, :time_to_release]
  layout "minimal"
  
  attr_reader :tickets, :start_date, :end_date
  
  def index
    @title = "Reports"
  end
  
  def queue_age
    results = benchmark("pluck") do
      tickets.joins(<<-SQL)
        LEFT OUTER JOIN generate_series('#{start_date}'::timestamp, '#{end_date}'::timestamp, '1 month') AS months(month)
          ON tickets.created_at <= months.month
          AND (tickets.closed_at IS NULL OR tickets.closed_at > months.month)
      SQL
        .where("months.month IS NOT NULL")
        .reorder("months.month ASC")
        .pluck("months.month::date", "extract('epoch' from month - tickets.created_at)")
    end
    
    results = benchmark("process") do
      results \
       .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(date, age), map| map[date].push(age) }
       .map { |date, ages| [date] + to_age_bins(ages) }
    end
    
    line = benchmark("line") do
      tickets.closed
        .group("date_trunc('month', closed_at)::date")
        .reorder("date_trunc('month', closed_at)::date")
        .pluck("date_trunc('month', closed_at)::date", "COUNT(id)")
        .map { |(month, count)| {date: month, y: count} }
    end
    
    benchmark("present") do
      render json: {data: results, line: line}
    end
  end
  
  def cycle_time
    results = benchmark("pluck") do
      tickets.joins(<<-SQL)
        LEFT OUTER JOIN generate_series('#{start_date}'::timestamp, '#{end_date}'::timestamp, '1 month') AS months(month)
          ON tickets.created_at <= months.month
          AND (tickets.closed_at IS NULL OR tickets.closed_at > months.month)
      SQL
        .where("months.month IS NOT NULL")
        .group("months.month")
        .reorder("months.month ASC")
        .pluck("months.month::date", "AVG(extract('epoch' from month - tickets.created_at)) / 86400")
    end
    
    benchmark("present") do
      render json: results
    end
  end
  
  def time_to_release
    results = benchmark("pluck") do
      Ticket.connection.select_rows(<<-SQL)
        SELECT
          months.month::date,
          AVG(extract('epoch' from q.closed_at - q.to_staging_at)) / 86400,
          AVG(extract('epoch' from q.released_at - q.closed_at)) / 86400
        FROM generate_series('#{start_date}'::timestamp, '#{end_date}'::timestamp, '1 month') AS months(month)
        LEFT OUTER JOIN (
          SELECT
            to_staging.created_at "to_staging_at",
            tickets.closed_at,
            to_production.created_at "released_at"
          FROM tickets
          
          INNER JOIN (
            SELECT rt1.ticket_id, MIN(r1.created_at) "created_at"
            FROM releases r1
            INNER JOIN releases_tickets rt1 ON rt1.release_id=r1.id
            WHERE r1.environment_name = 'Staging'
            GROUP BY rt1.ticket_id
          ) AS to_staging ON to_staging.ticket_id=tickets.id
          
          INNER JOIN (
            SELECT rt2.ticket_id, MIN(r2.created_at) "created_at"
            FROM releases r2
            INNER JOIN releases_tickets rt2 ON rt2.release_id=r2.id
            WHERE r2.environment_name = 'Production'
            GROUP BY rt2.ticket_id
          ) AS to_production ON to_production.ticket_id=tickets.id
          
        ) AS q
          ON q.released_at >= months.month
          AND q.released_at < (months.month + interval '1 month')
        WHERE q.closed_at > q.to_staging_at
          AND q.released_at > q.closed_at
        GROUP BY months.month
        ORDER BY months.month ASC
      SQL
        .map { |(date, v1, v2, v3)| [date.to_date, v1.to_i, v2.to_i, v3.to_i] }
    end
    
    benchmark("present") do
      render json: results
    end
  end
  
  def time_to_first_test
    results = benchmark("pluck") do
      Ticket.connection.select_rows(<<-SQL)
        SELECT
          months.month::date,
          AVG(extract('epoch' from q.testing_started_at - q.to_staging_at)) / 3600
        FROM generate_series('#{start_date}'::timestamp, '#{end_date}'::timestamp, '1 month') AS months(month)
        LEFT OUTER JOIN (
          SELECT
            to_staging.created_at "to_staging_at",
            first_test.created_at "testing_started_at"
          FROM tickets
          
          INNER JOIN (
            SELECT rt1.ticket_id, MIN(r1.created_at) "created_at"
            FROM releases r1
            INNER JOIN releases_tickets rt1 ON rt1.release_id=r1.id
            WHERE r1.environment_name = 'Staging'
            GROUP BY rt1.ticket_id
          ) AS to_staging ON to_staging.ticket_id=tickets.id
          
          INNER JOIN (
            SELECT tn.ticket_id, MIN(tn.created_at) "created_at"
            FROM testing_notes tn
            GROUP BY tn.ticket_id
          ) AS first_test ON first_test.ticket_id=tickets.id
          
        ) AS q
          ON q.to_staging_at >= months.month
          AND q.to_staging_at < (months.month + interval '1 month')
        WHERE q.testing_started_at > q.to_staging_at
        GROUP BY months.month
        ORDER BY months.month ASC
      SQL
        .map { |(date, v1, v2, v3)| [date.to_date, v1.to_i, v2.to_i, v3.to_i] }
    end
    
    benchmark("present") do
      render json: results
    end
  end
  
  
  
  def velocity
    @title = "Reports"
    @tickets = ::Ticket.includes(:project, :tasks).estimated.closed
      .select { |ticket| ticket.commit_time > 0 } # <-- speed up
  end
  
  def sprint
    @title = "Sprint Reports"
    @start_date = Date.parse(params.fetch(:since, "2014-05-18")) # when tasks were added
    @start_date = Date.parse(params.fetch(:since, "2014-08-07"))
    @start_date = @start_date.strftime "%Y-%m-%d"
    @end_date = Date.today.strftime "%Y-%m-%d"
    
    @users = []
    ([nil] + User.developers).each do |user|
      data = Ticket.connection.select_rows(<<-SQL)
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
        
        WHERE sprints.end_date BETWEEN '#{start_date}' AND '#{end_date}'
        GROUP BY sprints.end_date
        ORDER BY sprints.end_date ASC
      SQL
        .map { |(date, completed, checked_out)| [date.to_date, completed.to_f, checked_out.to_f - completed.to_f] }
      
      next if data.all? { |(_, completed, missed)| (completed + missed).zero? }
      average = data
        .select { |_, completed, missed| (completed + missed) > 0 }
        .avg { |(_, completed, _)| completed }
      @users.push [(user ? user.name : "Team"), average, data] # <- data is: [<date>, <completed>, <missed>]
    end
    @users.sort_by! { |(_, average, _)| -average }
  end
  
  
  
private
  
  CUTOFFS = [3.weeks, 3.months, 9.months, 2.years, 99.years].freeze
  
  def to_age_bins(ages)
    ages.each_with_object([0, 0, 0, 0, 0]) do |age, bins|
      bins[to_bin(age)] += 1
    end
  end
  
  def to_bin(age)
    CUTOFFS.each_with_index do |cutoff, i|
      return i if age < cutoff
    end
  end
  
  def find_tickets
    @tickets = Ticket.reorder(:created_at)
    @tickets = tickets.where(project_id: params[:project_id]) if params[:project_id]
    @tickets = tickets.where(project_id: params[:projects].split(",")) if params[:projects]
    
    @start_date = params.fetch(:since, "2010-01-01")
    @end_date = Date.today.strftime "%Y-%m-%d"
  end
  
end
