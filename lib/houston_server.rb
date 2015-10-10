module Houston

  def self.server?
    !!server
  end

  def self.server
    @server ||= discover_server
  end

private

  def self.discover_server
    if defined?(::PhusionPassenger)
      :passenger
    elsif defined?(::Unicorn) && defined?(::Unicorn::HttpServer) && in_object_space?(::Unicorn::HttpServer)
      :unicorn
    else
      $WEB_SERVER
    end
  end

  def self.in_object_space?(klass)
    ObjectSpace.each_object(klass).any?
  end

end

if Houston.server?
  puts "\e[94mRunning as a #{Houston.server.inspect} application\e[0m"
end
