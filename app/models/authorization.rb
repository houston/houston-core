class Authorization < ActiveRecord::Base

  belongs_to :user

  validates :name, :user_id, presence: true

  def self.[](name)
    find_by(name: name)
  end

  def self.set_access_token!(params)
    Authorization.find(params.fetch(:state)).tap do |authorization|
      authorization.get_access_token! params.fetch(:code)
    end
  end

  def provider
    Houston.oauth.get_provider(provider_name)
  end

  def granted?
    access_token.present?
  end

  def authorize_url(params={})
    provider.authorize_url params.merge(scope: scope, state: id)
  end

  def refresh!
    merge! provider.refresh_access_token(self)
  end

  def get_access_token!(code)
    merge! provider.redeem_access_token(code)
  end

  def access_token
    refresh! if expired?
    super
  end

  def expired?
    return false if expires_in.nil?
    Time.now >= expires_at
  end

private

  def merge!(new_token)
    self.access_token = new_token.token
    self.expires_in = new_token.expires_in
    self.expires_at = expires_in.seconds.from_now if expires_in
    self.refresh_token = new_token.refresh_token if new_token.respond_to?(:refresh_token)
    self.secret = new_token.secret if new_token.respond_to?(:secret)
    save!
  end

end
