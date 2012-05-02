class Unfuddle
  class Base < ActiveResource::Base
    
    self.format               = :json
    self.include_root_in_json = true
    self.user                 = Unfuddle.instance.username
    self.password             = Unfuddle.instance.password
    self.site                 = "https://#{Unfuddle.instance.subdomain}.unfuddle.com/api/v1"
    
  end
end
