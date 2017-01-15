module Houston
  module TestHelpers

    # !warning: knows an _awful_ lot about Houston::Observer's implementation!
    # Intended to keep Houston from firing the _actual_ post_receive hooks
    def with_exclusive_observation
      previous_observers = Houston.observer.instance_variable_get(:@observers)
      begin
        Houston.observer.clear!
        yield
      ensure
        Houston.observer.instance_variable_set(:@observers, previous_observers)
      end
    end

    def assert_triggered(event_name, message=nil)
      with_exclusive_observation do

        event_triggered = false
        Houston.observer.on event_name do
          event_triggered = true
        end

        yield

        assert event_triggered, ["The event \"#{event_name}\" was not triggered", message].compact.join
      end
    end

    def assert_not_triggered(event_name, message=nil)
      with_exclusive_observation do

        event_triggered = false
        Houston.observer.on event_name do
          event_triggered = true
        end

        yield

        refute event_triggered, ["The event \"#{event_name}\" was triggered", message].compact.join
      end
    end

  end
end
