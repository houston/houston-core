# Configuration for GitHub
# Use the following command to generate an access_token
# for your GitHub account to allow Houston to modify
# commit statuses.
#
# curl -v -u USERNAME -X POST https://api.github.com/authorizations --data '{"scopes":["repo:status"]}'
#
Houston.config.github do
  # Access token for houstonbot with scopes: ["repo"]
  access_token ENV["HOUSTON_GITHUB_ACCESS_TOKEN"]
  key ENV["HOUSTON_GITHUB_KEY"]
  secret ENV["HOUSTON_GITHUB_SECRET"]
  organization "my-company"
end
