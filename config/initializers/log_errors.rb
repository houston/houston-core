Houston.observer.on "error:create" do |error|
  Rails.logger.error "[error:#{error.category}] #{error.message}"
end
