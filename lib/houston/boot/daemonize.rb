module Houston

  def self.daemonize(name)
    unless Houston.running_as_web_server? or ENV["HOUSTON_DAEMONS"].to_s.split(",").member?(name)
      puts "\e[94m[daemon:#{name}] Skipping daemon since we're not running as a server\e[0m" if Rails.env.development?
      Rails.logger.info "\e[94m[daemon:#{name}] Skipping daemon since we're not running as a server\e[0m"
      return
    end

    puts "\e[94m[daemon:#{name}] Connecting\e[0m" if Rails.env.development?
    Rails.logger.info "\e[94m[daemon:#{name}] Connecting\e[0m"
    Thread.new do
      begin
        connected_at = Time.now
        Houston.observer.fire "daemon:#{name}:start"
        yield
        Houston.observer.fire "daemon:#{name}:started"

      rescue Exception
        puts "\e[91m#{$!.class}: #{$!.message}\e[0m" if Rails.env.development?
        Houston.report_exception $!
        unless (Time.now - connected_at) < 60
          Houston.observer.fire "daemon:#{name}:restart"
          retry
        end
      end

      # This should never happen
      puts "\e[31m[daemon:#{name}] Disconnected\e[0m" if Rails.env.development?
      Rails.logger.error "\e[31m[daemon:#{name}] Disconnected\e[0m"

      # http://stackoverflow.com/a/3516003/731300
      Rails.logger.flush
      Houston.observer.fire "daemon:#{name}:stop"
    end
  end

end
