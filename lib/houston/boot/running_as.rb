module Houston

  [:web_server, :script, :websocket_server].each do |process_type|
    module_eval <<-RUBY, __FILE__, __LINE__ + 1
    def self.running_as_#{process_type}?
      running_as == :#{process_type}
    end
    RUBY
  end

  def self.server?
    Houston.deprecation_notice "Houston.server? is deprecated; use Houston.running_as_web_server?"
    running_as_web_server?
  end

  def self.running_as
    @__process_type ||= discover_process_type
  end

private

  def self.discover_process_type
    return $HOUSTON_PROCESS_TYPE if $HOUSTON_PROCESS_TYPE
    return :web_server if $WEB_SERVER == :rack
    :script
  end

end
