class UserCredentials < ActiveRecord::Base

  class MissingCredentials < RuntimeError; end
  class InsufficientPermissions < RuntimeError; end
  class InvalidCredentials < RuntimeError; end
  class AccountLocked < RuntimeError; end

  encrypt_with_public_key :password, key_pair: Houston.config.keypair

  validate :test_connection
  validates :service, inclusion: { in: Houston.user_credentials_support_services }

  belongs_to :user

  def self.for(service)
    credentials = where(service: service).first || (raise MissingCredentials)
    [credentials.login, credentials.password.decrypt(Houston.config.passphrase)]
  rescue OpenSSL::PKey::RSAError
    credentials.delete
    raise MissingCredentials
  end

  def test_connection
    Houston.test_connection_to(self)
  end

end
