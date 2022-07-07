# Listen for all events
# See whether any ActionCable client is subscribed to them
# and, if so, broadcast the event over ActionCable.
Houston.observer.on :* do |event, params|
  event_channel = EventsChannel.name_of(event)
  channels = case ActionCable.server.pubsub.class.name
  when "ActionCable::SubscriptionAdapter::Async"
    ActionCable.server.pubsub.send(:subscriber_map).instance_variable_get(:@subscribers).keys
  when "ActionCable::SubscriptionAdapter::Redis"
    ActionCable.server.pubsub.redis_connection_for_subscriptions.pubsub("channels")
  end

  if channels.member? event_channel
    params = JSON.load(Houston::Serializer.new.dump(params))
    ActionCable.server.broadcast(EventsChannel.name_of(event), params)
  end
end
