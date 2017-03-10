class Authorization < ActiveRecord::Base
  include Houston::Props

  belongs_to :user

  validates :user_id, presence: true

  after_destroy do
    next unless granted?
    Houston.observer.fire "authorization:revoke", authorization: self
  end



  class << self
    def for(user)
      where(user_id: user.id)
    end

    def granted
      where.not(access_token: nil)
    end

    def with_scope(*scopes)
      where("regexp_split_to_array(scope, '[,\\s]+') @> ARRAY[?]", scopes)
    end
    alias :with_scopes :with_scope



    def providers
      Houston.config.oauth_providers.map(&:classify)
    end

    def provider
      @provider ||= Houston.oauth.get_provider(name.underscore)
    end

    def set_access_token!(params)
      Authorization.find(params.fetch(:state)).tap do |authorization|
        authorization.get_access_token! params.fetch(:code)
      end
    end
  end



  def provider
    self.class.provider
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

  def url
    "#{Houston.root_url}/auth/#{id}"
  end

private

  def merge!(new_token)
    self.access_token = new_token.token
    self.expires_in = new_token.expires_in
    self.expires_at = expires_in.seconds.from_now if expires_in
    self.refresh_token = new_token.refresh_token if new_token.respond_to?(:refresh_token)
    self.secret = new_token.secret if new_token.respond_to?(:secret)
    save!

    Houston.observer.fire "authorization:grant", authorization: self
  end

end

Houston.config.oauth_providers.each do |provider|
  require_dependency provider
end
