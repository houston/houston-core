# We can observe any event and then broadcast it to interested
# clients via ActionCable.
#
# To reduce work for ActionCable, we don't broadcast *all*
# events. Instead, this class observes an event on-demand ---
# as soon as a websocket client subscribes to it --- and ensures
# that Houston only observes each event once.
#
module Houston
  class ObserverSubscriber

    def initialize
      @mutex = Mutex.new
      @subscribed_events = []
    end

    def add(event)
      mutex.synchronize do
        return if subscribed_events.member?(event)

        Rails.logger.info "\e[34m[subscriber] Listening to \e[1m#{event}\e[0m"
        subscribed_events << event
        Houston.observer.on event do |params|
          broadcast_event event, params
        end
      end
    end

  private
    attr_reader :mutex, :subscribed_events

    def broadcast_event(event, params)
      Rails.logger.info "\e[34m[subscriber] Broadcasting \e[1m#{event}\e[0m"
      params = MultiJson.load(Houston::Serializer.new.dump(params))
      ActionCable.server.broadcast(EventsChannel.name_of(event), params)
    end

  end

  @observer_subscriber = Houston::ObserverSubscriber.new

  class << self
    attr_reader :observer_subscriber
  end
end
