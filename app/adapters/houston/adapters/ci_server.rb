require File.dirname(__FILE__)

Houston::Adapters.define_adapter_namespace "CIServer"

# !todo: move this somewhere else

module Houston
  module Adapters
    module CIServer
      
      def self.post_build_callback_url(project)
        Rails.application.routes.url_helpers.web_hook_url(
          host: Houston.config.host,
          project_id: project.slug,
          hook: "post_build")
      end
      
    end
  end
end

require "houston/adapters/ci_server/errors"
