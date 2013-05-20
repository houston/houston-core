class UserCredentials < ActiveRecord::Base
  
  class MissingCredentials < RuntimeError; end
  
  encrypt_with_public_key :password, key_pair: Houston.config.keypair
  
  belongs_to :user
  
  def self.for(service)
    where(service: service).first || (raise MissingCredentials)
  end
  
end
