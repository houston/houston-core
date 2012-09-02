Airbrake.configure do |config|
  config.api_key  = '8ca3055643a8dc96a9bcea57f8ad0dee'
  config.host     = 'errbit.cphepdev.com'
  config.port     = 80
  config.secure   = config.port == 443
end
