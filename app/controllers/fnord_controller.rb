class FnordController < ApplicationController
  
  def index
  end
  
  def demography
    # Just a JSON form of the information in the config file (fnordmetric.rb)
    render content_type: "text/json", text: '{"title":"Demography","widgets":{"agedistributionfemaleusersmonthly":{"title":"Age Distribution (female) monthly","width":50,"klass":"BarsWidget","gauge":"age_distribution_female_monthly","autoupdate":5,"order_by":"field","plot_style":"vertical","async_chart":true,"color":"#4572a7","tick":2592000},"agedistributionmaleusersmonthly":{"title":"Age Distribution (male) monthly","width":50,"klass":"BarsWidget","gauge":"age_distribution_male_monthly","autoupdate":5,"order_by":"field","plot_style":"vertical","async_chart":true,"color":"#4572a7","tick":2592000},"agedistributionfemaleusers":{"title":"Age Distribution: Female Users","width":50,"klass":"ToplistWidget","gauges":{"age_distribution_female_monthly":{"tick":2592000,"title":"Age Distribution (female) monthly"},"age_distribution_female_daily":{"tick":86400,"title":"Age Distribution (female) daily"}},"autoupdate":5,"render_target":null,"ticks":null,"click_callback":null,"async_chart":true,"tick":null},"agedistributionmaleusers":{"title":"Age Distribution: Male Users","width":50,"klass":"ToplistWidget","gauges":{"age_distribution_male_monthly":{"tick":2592000,"title":"Age Distribution (male) monthly"},"age_distribution_male_daily":{"tick":86400,"title":"Age Distribution (male) daily"}},"autoupdate":5,"render_target":null,"ticks":null,"click_callback":null,"async_chart":true,"tick":null}}}'
  end
  
  def tech_stats
    # Just a JSON form of the information in the config file (fnordmetric.rb)
    render content_type: "text/json", text: '{"title":"TechStats","widgets":{"eventsperminute":{"title":"Events per Minute","width":100,"klass":"TimelineWidget","series":[{"name":"events_per_minute","data":[{"x":1350229320,"y":0}],"color":"#4572a7"}],"gauges":["events_per_minute"],"start_timestamp":1350229320,"end_timestamp":1350231120,"autoupdate":30,"include_current":true,"default_style":"line","async_chart":true,"tick":60},"eventsperhour":{"title":"Events per Hour","width":50,"klass":"TimelineWidget","series":[{"name":"events_per_hour","data":[{"x":1350144000,"y":0}],"color":"#4572a7"}],"gauges":["events_per_hour"],"start_timestamp":1350144000,"end_timestamp":1350230400,"autoupdate":30,"include_current":true,"default_style":"line","async_chart":true,"tick":3600},"eventssecond":{"title":"Events/Second","width":50,"klass":"TimelineWidget","series":[{"name":"events_per_second","data":[{"x":1350231148,"y":0}],"color":"#4572a7"}],"gauges":["events_per_second"],"start_timestamp":1350231148,"end_timestamp":1350231178,"autoupdate":1,"include_current":true,"default_style":"areaspline","async_chart":true,"tick":1},"eventsnumbers":{"title":"Events Numbers","width":100,"klass":"NumbersWidget","series":["events_per_second","events_per_minute","events_per_hour"],"offsets":[1,3,5,10],"autoupdate":1}}}'
  end
  
end
