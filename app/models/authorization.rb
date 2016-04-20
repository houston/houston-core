class Authorization < ActiveRecord::Base

  belongs_to :provider, class_name: "Oauth::Provider"

  validates :name, :provider_id, presence: true

  def self.[](name)
    find_by(name: name)
  end

  def self.set_access_token!(params)
    Authorization.find(params.fetch(:state)).tap do |authorization|
      authorization.get_access_token! params.fetch(:code)
    end
  end

  def granted?
    expires_in.present?
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
    return false unless granted?
    Time.now >= expires_at
  end

private

  def merge!(new_token)
    self.access_token = new_token.token
    self.expires_in = new_token.expires_in
    self.expires_at = expires_in.seconds.from_now
    self.refresh_token = new_token.refresh_token if new_token.respond_to?(:refresh_token)
    self.secret = new_token.secret if new_token.respond_to?(:secret)
    save!
  end

end
