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
  
  def parse_github_style_agent(params)
    return nil unless params.key?("email")
    return params["email"] unless params.key?("name")
    "#{params["name"].inspect} <#{params["email"]}>"
  end
  
end
