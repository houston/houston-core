class TasksExcelPresenter
  include OpenXml::Xlsx::Elements

  attr_reader :tasks

  def initialize(tasks)
    @tasks = tasks
  end

  def to_s
    package = OpenXml::Xlsx::Package.new
    worksheet = package.workbook.worksheets[0]

    tasks = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
      self.tasks.includes(:project, :ticket).load
    end if self.tasks.is_a?(ActiveRecord::Relation)

    title = {
      font: Font.new("Calibri", 16) }
    heading = {
      alignment: Alignment.new("left", "center") }
    general = {
      alignment: Alignment.new("left", "center") }
    timestamp = {
      format: NumberFormat::DATETIME,
      alignment: Alignment.new("right", "center") }
    integer = {
      format: NumberFormat::INTEGER,
      alignment: Alignment.new("right", "center") }
    number = {
      format: NumberFormat::DECIMAL,
      alignment: Alignment.new("right", "center") }

    worksheet.add_row(
      number: 2,
      cells: [
        { column: 2, value: "Tasks", style: title, height: 24 }])

    headers = %w{Project Description Completed Estimate}
    worksheet.add_row(
      number: 3,
      cells: [
        { column: 2, value: "Project", style: heading },
        { column: 3, value: "Description", style: heading },
        { column: 4, value: "Completed", style: heading },
        { column: 5, value: "Estimate", style: heading },
        { column: 6, value: "Hours", style: heading },
        { column: 7, value: "Names", style: heading },
      ])

    tasks.each_with_index do |task, i|
      commits = commits_by_task_id.fetch(task.id, [])
      worksheet.add_row(
        number: i + 4,
        cells: [
          { column: 2, value: task.project.try(:name), style: general },
          { column: 3, value: task.description, style: general },
          { column: 4, value: task.completed_at, style: timestamp },
          { column: 5, value: task.effort, style: number },
          { column: 6, value: commit_time(commits), style: number },
          { column: 7, value: committers(commits).join("; "), style: general },
        ])
    end

    worksheet.column_widths({
      1 => 3.8,
      2 => 18,
      3 => 72,
      4 => 15,
      5 => 10,
      6 => 10,
      7 => 40,
    })

    worksheet.add_table 1, "Tasks", "B3:G#{tasks.length + 3}", [
      TableColumn.new("Project"),
      TableColumn.new("Description"),
      TableColumn.new("Completed"),
      TableColumn.new("Estimate"),
      TableColumn.new("Hours"),
      TableColumn.new("Names")
    ]

    Houston.benchmark "[#{self.class.name.underscore}] Prepare file" do
      package.to_stream.string
    end
  end

private

  def commit_time(commits)
    return nil if commits.none?
    commits.sum { |_, message, _| Commit.parse_message(message)[:hours_worked] }
  end

  def committers(commits)
    commits.flat_map { |_, _, committer| committer.split(" and ") }.uniq
  end

  def commits_by_task_id
    @commits_by_task_id ||= Commit.joins(:tasks).merge(tasks)
      .pluck("tasks.id", :message, :committer)
      .group_by { |id, _, _| id }
  end


end
