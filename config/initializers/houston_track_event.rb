module Houston
  
  # !todo: do this in a separate thread
  # !todo: configure w/o globals
  def self.track_event(user, event_name, metadata={})
    if Houston.config.use_intercom?
      Intercom.app_id = Houston.config.intercom[:app_id]
      Intercom.app_api_key = Houston.config.intercom[:app_api_key]
      Intercom::Event.create(
        event_name: event_name,
        email: user.email,
        user_id: user.id,
        created_at: Time.now.to_i,
        metadata: metadata)
    end
  end
  
end
