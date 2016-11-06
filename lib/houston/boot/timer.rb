require "thread_safe"


require "attentive"
require "attentive/entity"

Attentive::Entity.define "houston.trigger.every",
    "{{duration:core.time.duration}}",
    "day at {{time:core.time}}",
    "weekday at {{time:core.time}}",
    "{{wday:core.date.wday}} at {{time:core.time}}",
    published: false do |match|

  if match.matched?("duration")
    duration = match["duration"]
    seconds = duration.seconds + duration.minutes * 60 + duration.hours * 3600
    [ :every, "#{seconds}s" ]

  elsif match.matched?("time")
    time = match["time"]
    days = match["wday"] if match.matched?("wday")
    days = "*" if match.to_s.starts_with?("day")
    days = "1-5" if match.to_s.starts_with?("weekday")
    [ :cron, "#{time.min} #{time.hour} * * #{days}" ]

  else
    nomatch!
  end
end

TRIGGER_PHRASE = Attentive::Tokenizer.tokenize("{{houston.trigger.every}}", entities: true).freeze


module Houston
  class Timer

    def initialize
      @queued_timers = ThreadSafe::Array.new

      Houston.observer.on "daemon:scheduler:start", raise: true do
        schedule_queued_timers!
      end
    end

    def every(interval, &block)
      return schedule_later :every, interval, block unless $scheduler

      match = Attentive::Matcher.match!(TRIGGER_PHRASE, interval)
      raise ArgumentError, "Unrecognized interval: #{interval.inspect}" unless match
      method_name, argument = match["houston.trigger.every"]
      $scheduler.public_send method_name, argument, &block
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
