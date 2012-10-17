require "fnordmetric"



class FnordMetric::CustomWidget < FnordMetric::TimeseriesWidget
  
  def self.execute(namespace, event)
    return false unless event["cmd"] == "values_at"
    
    gkey = event["gauges"].first
    gauge = namespace.gauges[gkey.to_sym] || raise("#{gkey.to_sym.inspect} is not a recognized gauge")
    data = data_for(gauge, event)
    
    { :class => "widget_response",
      :widget_key => event["widget_key"],
      :cmd => :values_at,
      :data => data }
  end
  
  def self.data_for(gauge)
    raise NotImplementedError
  end
  
end

class FnordMetric::ResponsetimeWidget < FnordMetric::CustomWidget
  
  def self.data_for(gauge, event)
    {event["widget_key"] => gauge.value_at(event["until"])}
  end
  
end

class FnordMetric::ResponsestatusWidget < FnordMetric::CustomWidget
  
  def self.data_for(gauge, event)
    Hash[gauge.field_values_at(event["until"]).map { |(key, value)| [key, value.to_i] }]
  end

end



FnordMetric.namespace :changelog do
  
  gauge :average_response_time, tick: 1.second, average: true
  gauge :responses_by_status_code, tick: 1.second, three_dimensional: true
  
  event :response do
    incr :average_response_time, data[:time].to_i
    incr_field :responses_by_status_code, data[:status]
  end
  
  widget "Dashboard",
    title: "Average Response Time",
    type: :responsetime,
    gauges: [:average_response_time],
    autoupdate: 1
  
  widget "Dashboard",
    title: "Response Status Codes",
    type: :responsestatus,
    gauges: [:responses_by_status_code],
    autoupdate: 1
  
end



FnordMetric.options = {
  :event_queue_ttl  => 10, # all data that isn't processed within 10s is discarded to prevent memory overruns
  :event_data_ttl   => 1, # 3600, # event data is stored for one hour (needed for the active users view)
  :session_data_ttl => 1, # 3600, # session data is stored for one hour (needed for the active users view)
  :redis_prefix => "fnordmetric"
}

FnordMetric::Web.new(:port => 4242)
FnordMetric::Acceptor.new(:protocol => :udp, :port => 2323)
FnordMetric::Worker.new
FnordMetric.run
