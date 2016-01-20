module Api
  module V1
    class SprintTasksController < ApplicationController
      before_filter :api_authenticate!
      before_filter :find_sprint
      before_filter :find_task, only: [:create, :destroy]
      skip_before_filter :verify_authenticity_token

      attr_reader :sprint, :task

      rescue_from ActiveRecord::RecordNotFound do
        head 404
      end

      def index
        render json: sprint.tasks
          .includes(:ticket => :project)
          .map { |task| present_task(task) }
      end

      def mine
        render json: sprint.tasks
          .includes(:ticket => :project)
          .checked_out_by(current_user, during: sprint)
          .map { |task| present_task(task) }
      end

      def create
        authorize! :update, sprint

        if sprint.completed?
          render text: "The Sprint is completed. You cannot add or remove tasks.", status: :unprocessable_entity
          return
        end

        if sprint.locked? && !task.ticket_id.in?(sprint.ticket_ids)
          render text: "The Sprint is locked. You can add tasks for tickets that are already in the Sprint, but you can't add new tickets to the Sprint.", status: :unprocessable_entity
          return
        end

        # Putting a task into a Sprint implies that you're able to estimate this ticket
        task.ticket.able_to_estimate! if task.ticket.respond_to?(:able_to_estimate!)

        task.update_attributes(effort: params[:effort]) if params[:effort]

        if task.completed? && task.completed_at < sprint.starts_at
          render text: "Task ##{task.shorthand} cannot be added to the Sprint because it was completed before the Sprint began", status: :unprocessable_entity
        elsif task.effort.nil? or task.effort.zero?
          render text: "Task ##{task.shorthand} cannot be added to the Sprint because it has no effort", status: :unprocessable_entity
        else
          sprint.tasks.add task
          task.check_out!(sprint, current_user) unless task.checked_out?(sprint)
          render json: SprintTaskPresenter.new(sprint, task).to_json
        end
      end

      def destroy
        authorize! :update, sprint

        if sprint.completed?
          render text: "The Sprint is completed. You cannot add or remove tasks.", status: :unprocessable_entity
          return
        end

        if sprint.locked?
          render text: "The Sprint is locked; tasks cannot be removed", status: :unprocessable_entity
          return
        end

        SprintTask.where(sprint_id: sprint.id, task_id: task.id).delete_all
        head :ok
      end

    private

      def present_task(task)
        { projectSlug: task.project.slug,
          number: task.number,
          shorthand: task.shorthand,
          description: task.description,
          effort: task.effort,
          committedAt: task.first_commit_at,
          releasedAt: task.first_release_at,
          completedAt: task.completed_at }
      end

      def find_sprint
        @sprint = Sprint.current || Sprint.new
      end

      def find_task
        @task = Task.find_by_project_and_shorthand(params[:project_slug], params[:shorthand]) || (raise ActiveRecord::RecordNotFound)
      end

    end
  end
end
