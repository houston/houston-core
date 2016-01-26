class ProjectTestsController < ApplicationController

  def index
    @project = Project.find_by_slug! params[:slug]
    @title = "#{@project.name} Tests"

    head = params.fetch :at, @project.head_sha
    commits = params.fetch(:limit, 250).to_i

    @commits = Houston.benchmark("[project_tests#index] fetch commits") {
      @project.repo.ancestors(head, including_self: true, limit: commits) }
    shas = @commits.map(&:sha)
    test_run_id_by_sha = Hash[@project.test_runs.where(sha: shas).pluck(:sha, :id)]
    test_run_ids = test_run_id_by_sha.values

    # We're looking at the history of the tests that exist in the
    # most recent commit; ignore tests that didn't exist before this
    test_ids = Houston.benchmark("[project_tests#index] pick tests") do
      latest_test_run_id = @project.test_runs.where(sha: shas)
        .joins("LEFT OUTER JOIN test_results ON test_runs.id=test_results.test_run_id")
        .where.not("test_results.test_run_id" => nil)
        .limit(1)
        .pluck(:id)
        .first
      TestResult.where(test_run_id: latest_test_run_id).pluck("DISTINCT test_id")
    end

    # Get all the results that we're going to graph
    test_results = Houston.benchmark("[project_tests#index] load results") do
      TestResult.where(test_run_id: test_run_ids, test_id: test_ids).pluck(:test_run_id, :test_id, :status, :duration)
    end

    # Now we need to map results to tests
    # and make sure that they're in the same order
    # that the last 200 commits occurred in.
    @tests = Houston.benchmark("[project_tests#index] map results") do
      map = Hash.new { |hash, test_id| hash[test_id] = {} }
      durations = Hash.new { |hash, test_id| hash[test_id] = [] }
      test_results.each do |(test_run_id, test_id, status, duration)|
        map[test_id][test_run_id] = status
        durations[test_id] << duration
      end

      @project.tests
        .where(id: test_ids)
        .order(:suite, :name)
        .pluck("tests.id", :suite, :name)
        .map do |(id, suite, name)|
          status_by_test_run_id = map[id]
          d = durations[id]
          { id: id,
            suite: suite,
            name: name,
            duration_avg: d.mean,
            duration5: d.percentile(5),
            duration95: d.percentile(95),
            results: shas.map { |sha| status_by_test_run_id[test_run_id_by_sha[sha]] } }
        end
    end
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
          .select("test_runs.sha", "test_results.*")
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
