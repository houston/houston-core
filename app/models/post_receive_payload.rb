class PostReceivePayload
  
  def initialize(params)
    parse_params(params)
  end
  
  attr_accessor :agent_email, :commit, :branch
  
  def parsed?
    commit.present?
  end
  
  def parse_params(params)
    json_payload = params.key?("payload") && JSON.parse(params["payload"]) rescue nil
    parse_github_style_params(json_payload) if json_payload
  end
  
  def parse_github_style_params(params)
    self.commit = params["after"]
    self.agent_email = parse_github_style_agent(params["pusher"])
    self.branch = params["ref"].split("/").last if params.key?("ref")
  end
  
  def parse_github_style_agent(pusher)
    return nil unless pusher && pusher.key?("email")
    return pusher["email"] unless pusher.key?("name")
    "#{pusher["name"].inspect} <#{pusher["email"]}>"
  end
  
end
