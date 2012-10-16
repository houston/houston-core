require "fnordmetric"

STATUS_CODE_TO_GAUGE = Hash[Rack::Utils::SYMBOL_TO_STATUS_CODE.map { |symbol, status_code| [status_code, "#{symbol}_responses".to_sym] }]

FnordMetric.namespace :changelog do
  
  gauge :average_response_time, tick: 1.second, average: true
  
  STATUS_CODE_TO_GAUGE.values.each do |gauge_name|
    gauge gauge_name, tick: 1.second
  end
  
  event :response do
    puts "response_time: #{data[:time]}"
    incr :average_response_time, data[:time].to_i
    gauge = STATUS_CODE_TO_GAUGE[data[:status].to_i]
    if gauge
      incr gauge
    else
      puts "[ERROR] unknown status: #{data[:status].inspect}"
    end
  end
  
  widget "Dashboard",
    title: "Average Response Time",
    type: :timeline,
    width: 100,
    gauges: [:average_response_time],
    include_current: true,
    autoupdate: 1
  
  widget "Dashboard",
    title: "Response Status Codes",
    type: :timeline,
    width: 100,
    gauges: STATUS_CODE_TO_GAUGE.values,
    include_current: true,
    autoupdate: 1

end

FnordMetric.options = {
  :event_queue_ttl  => 10, # all data that isn't processed within 10s is discarded to prevent memory overruns
  :event_data_ttl   => 3600, # event data is stored for one hour (needed for the active users view)
  :session_data_ttl => 3600, # session data is stored for one hour (needed for the active users view)
  :redis_prefix => "fnordmetric"
}

FnordMetric::Web.new(:port => 4242)
FnordMetric::Acceptor.new(:protocol => :udp, :port => 2323)
FnordMetric::Worker.new
FnordMetric.run
