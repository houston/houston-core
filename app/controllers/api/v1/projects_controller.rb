module Api
  module V1
    class ProjectsController < ApplicationController
      before_action :api_authenticate!
      skip_before_action :verify_authenticity_token
      skip_around_action :with_current_project

      rescue_from ActiveRecord::RecordNotFound do
        head 404
      end

      def index
        @projects = Project.unretired
        render json: ProjectPresenter.new(@projects)
      end

    end
  end
end
