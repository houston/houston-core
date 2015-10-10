class GithubToken < Oauth2Token

  # skip refresh!
  def ensure_access
    self.class.find_or_create_from_access_token user, self
  end

end
