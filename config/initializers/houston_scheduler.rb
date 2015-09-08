require "rufus/scheduler"

Houston.daemonize "scheduler" do
  $scheduler = Rufus::Scheduler.new

  Houston.config.timers.each do |(type, param, name, options, block)|
    wrapped_block = Houston.jobs.method(:run_job)

    case type
    when :cron
      cronline = Whenever::Output::Cron.new(options.fetch(:every, :day), nil, param)
      $scheduler.cron cronline.time_in_cron_syntax, options.merge(tag: name), &wrapped_block

    when :every
      $scheduler.every param, options.merge(tag: name), &wrapped_block

    else
      raise NotImplementedError, "A #{type.inspect} timer is not implemented"
    end
  end

  $scheduler.join
end
