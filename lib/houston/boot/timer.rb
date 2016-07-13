require "thread_safe"

module Houston
  class Timer

    def initialize
      @queued_timers = ThreadSafe::Array.new

      Houston.observer.on "daemon:scheduler:start", raise: true do
        schedule_queued_timers!
      end
    end

    def at(time, &block)
      return schedule_later :at, time, block unless $scheduler

      days_of_the_week = :day
      days_of_the_week, time = *time if time.is_a?(Array)
      cronline = Whenever::Output::Cron.new(days_of_the_week, nil, time)
      $scheduler.cron cronline.time_in_cron_syntax, &block
    end

    def every(interval, &block)
      return schedule_later :every, interval, block unless $scheduler

      $scheduler.every interval, &block
    end

  private

    attr_reader :queued_timers

    def schedule_later(*args)
      queued_timers.push args
    end

    def schedule_queued_timers!
      while timer = queued_timers.pop
        method_name, value, block = timer
        public_send method_name, value, &block
      end
    end

  end
end
