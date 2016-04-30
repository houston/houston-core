module Api
  module V1
    class MeasurementsController < ApplicationController
      before_filter :api_authenticate!
      skip_before_filter :verify_authenticity_token

      rescue_from ActiveRecord::RecordNotFound do
        head 404
      end

      rescue_from KeyError do |e|
        render json: { error: e.message }, status: 422
      end

      def index
        name = params.fetch :name
        start_time = params.fetch :start
        end_time = params.fetch :end
        measurements = Measurement.named(name).taken_between(start_time, end_time)

        if slugs = params[:project]
          slugs = slugs.split(",") if slugs.is_a?(String)
          projects = Project.where(slug: slugs)
          measurements = measurements.where(subject: projects)
        end

        render json: MeasurementsPresenter.new(measurements)
      end

    end
  end
end
