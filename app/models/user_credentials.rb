class UserCredentials < ActiveRecord::Base
  
  class MissingCredentials < RuntimeError; end
  class InsufficientPermissions < RuntimeError; end
  class InvalidCredentials < RuntimeError; end
  class AccountLocked < RuntimeError; end
  
  encrypt_with_public_key :password, key_pair: Houston.config.keypair
  
  validate :test_connection
  
  belongs_to :user
  
  def self.for(service)
    where(service: service).first || (raise MissingCredentials)
  end
  
  
  
  def test_connection
    case service
    when "Unfuddle" then test_unfuddle_connection
    when "Github" then test_github_connection
    else raise NotImplementedError
    end
  end
  
  def test_github_connection
    password = self.password.decrypt(Houston.config.passphrase)
    Octokit::Client.new(login: login, password: password).user
  rescue Octokit::Forbidden
    errors.add(:base, "Account locked")
  rescue Octokit::Unauthorized
    errors.add(:base, "Invalid credentials")
  end
  
  def test_unfuddle_connection
    password = self.password.decrypt(Houston.config.passphrase)
    Unfuddle.with_config(username: login, password: password) { Unfuddle.instance.get("people/current") }
  rescue Unfuddle::UnauthorizedError
    errors.add(:base, "Invalid credentials")
  end
  
end
