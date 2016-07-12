require "thread_safe"

module Houston
  class Timer

    def initialize
      @queued_timers = ThreadSafe::Array.new

      Houston.observer.on "daemon:scheduler:start", raise: true do
        schedule_queued_timers!
      end
    end

    def at(time, action_name)
      return schedule_later :at, time, action_name unless $scheduler

      days_of_the_week = :day
      days_of_the_week, time = *time if time.is_a?(Array)
      cronline = Whenever::Output::Cron.new(days_of_the_week, nil, time)
      $scheduler.cron cronline.time_in_cron_syntax, {tag: action_name}, &method(:run)
    end

    def every(interval, action_name)
      return schedule_later :every, interval, action_name unless $scheduler

      $scheduler.every interval, {tag: action_name}, &method(:run)
    end

  private

    attr_reader :queued_timers

    def schedule_later(*args)
      queued_timers.push args
    end

    def schedule_queued_timers!
      while timer = queued_timers.pop
        public_send timer.shift, *timer
      end
    end

    def run(job)
      action_name, trigger = [job.tags.first, job.original]
      Houston.actions.run action_name, {}, trigger: trigger
    end

  end
end
