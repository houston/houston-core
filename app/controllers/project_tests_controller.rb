class ProjectTestsController < ApplicationController

  def index
    @project = Project.find_by_slug! params[:slug]
    @test = @project.tests.find params[:id]
    @totals = Hash[@test.test_results.group(:status).pluck(:status, "COUNT(*)")]

    head = params.fetch :at, @project.repo.branch("master")
    stop_shas = @test.introduced_in_shas
    @commits = Houston.benchmark("[project_tests#index] fetch commits") {
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

    if request.xhr?
      if @commits.any?
        render partial: "project_tests/commits"
      else
        head 204
      end
    end
  end

end
