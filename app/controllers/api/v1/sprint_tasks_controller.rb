module Api
  module V1
    class SprintTasksController < ApplicationController
      before_filter :api_authenticate!
      before_filter :find_sprint
      skip_before_filter :verify_authenticity_token
      
      attr_reader :sprint
      
      def index
        render json: sprint.tasks
          .includes(:ticket => :project)
          .map { |task| present_task(task) }
      end
      
      def mine
        render json: sprint.tasks
          .includes(:ticket => :project)
          .checked_out_by(current_user)
          .map { |task| present_task(task) }
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
          completedAt: task.first_release_at }
      end
      
      def find_sprint
        @sprint = Sprint.current || Sprint.new
      end
      
    end
  end
end
