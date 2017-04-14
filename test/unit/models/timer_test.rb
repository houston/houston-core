require "test_helper"

class TimerTest < ActiveSupport::TestCase


  context "Before Rufus Scheduler is started" do
    setup do
      teardown_scheduler!
    end

    context "Adding a timer" do
      should "add it to `queued_timers`" do
        callback = Proc.new { :ok }
        assert_difference "queued_timers.length", +1 do
          timers.every "5s", &callback
        end
      end
    end

    context "Removing a timer" do
      should "remove it from `queued_timers`" do
        callback = Proc.new { :ok }
        timers.every "5s", &callback

        assert_difference "queued_timers.length", -1 do
          timers.stop "5s", callback
        end
      end
    end
  end


  context "After Rufus Scheduler is started" do
    setup do
      setup_scheduler!
    end

    teardown do
      teardown_scheduler!
    end

    context "Adding a timer" do
      should "add a new job to the scheduler" do
        callback = Proc.new { :ok }
        assert_difference "scheduled_jobs.length", +1 do
          timers.every "5s", &callback
        end
      end
    end

    context "Removing a timer" do
      should "remove it from the scheduler's jobs" do
        callback = Proc.new { :ok }
        timers.every "5s", &callback

        assert_difference "scheduled_jobs.length", -1 do
          timers.stop "5s", callback
        end
      end
    end
  end


private

  def timers
    @timers ||= Houston::Timer.new
  end

  def queued_timers
    timers.send :queued_timers
  end

  def scheduled_jobs
    $scheduler.jobs
  end

  def setup_scheduler!
    teardown_scheduler!
    $scheduler = Rufus::Scheduler.new
  end

  def teardown_scheduler!
    $scheduler.shutdown if $scheduler
    $scheduler = nil
  end

end
