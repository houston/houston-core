class ProjectTestsController < ApplicationController

  def index
    @project = Project.find_by_slug! params[:slug]

    head = params.fetch :at, @project.head_sha
    commits = params.fetch(:limit, 500).to_i

    @commits = Houston.benchmark("[project_tests#index] fetch commits") {
      @project.repo.ancestors(head, including_self: true, limit: commits) }
    @runs = @project.test_runs.where(sha: @commits.map(&:sha))

    @tests = @project.tests.order(:suite, :name)
      .joins(<<-SQL)
        LEFT JOIN LATERAL (
          SELECT COUNT(*) FROM test_results
          WHERE test_results.test_run_id IN (#{@runs.pluck(:id).join(",")})
          AND test_results.status='pass'
          AND test_results.test_id=tests.id
        ) "passes" ON TRUE
        LEFT JOIN LATERAL (
          SELECT COUNT(*) FROM test_results
          WHERE test_results.test_run_id IN (#{@runs.pluck(:id).join(",")})
          AND test_results.status='fail'
          AND test_results.test_id=tests.id
        ) "fails" ON TRUE
      SQL
      .where("passes.count + fails.count > 0")
      .pluck("tests.id", "tests.suite", "tests.name", "passes.count", "fails.count")
  end

  def show
    @project = Project.find_by_slug! params[:slug]
    @test = @project.tests.find params[:id]
    @totals = Hash[@test.test_results.group(:status).pluck(:status, "COUNT(*)")]

    begin
      head = params.fetch :at, @project.head_sha
      stop_shas = @test.introduced_in_shas
      @commits = Houston.benchmark("[project_tests#show] fetch commits") {
        @project.repo.ancestors(head, including_self: true, limit: 100, hide: stop_shas) }

      if @commits.any?
        @runs = @project.test_runs.where(sha: @commits.map(&:sha))

        @commits.each do |commit|
          def commit.date
            @date ||= committed_at.to_date
          end
          def commit.time
            committed_at
          end
        end

        @results = @test.test_results.where(test_run_id: @runs.map(&:id))
          .joins(:test_run)
          .select("test_runs.sha", :*)
          .index_by { |result| result[:sha] }
        @runs = @runs.index_by(&:sha)
      end
    rescue Houston::Adapters::VersionControl::CommitNotFound
      @commits = []
      @exception = $!
    end

    if request.xhr?
      if @commits.any?
        render partial: "project_tests/commits"
      else
        head 204
      end
    end
  end

end
