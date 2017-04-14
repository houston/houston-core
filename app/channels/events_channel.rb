# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class EventsChannel < ApplicationCable::Channel

  def self.name_of(event)
    "events_#{event.gsub(":", "_")}"
  end

  def subscribed
    events = [params[:event]] if params.key?(:event)
    events = params[:events] if params.key?(:events)

    events.each do |event|
      unless Houston.events.registered?(event)
        Rails.logger.info "\e[31m[subscriber] \e[1m#{event}\e[0;31m is not a registered event\e[0m"
        next
      end

      Rails.logger.info "\e[34m[subscriber] Subscribing to \e[1m#{event}\e[0m"
      stream_from EventsChannel.name_of(event)
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end
