class DeployNotification
  
  def initialize(deploy)
    @deploy = deploy
    @deployer = deploy.deployer
    @maintainers = deploy.project.maintainers
  end
  
  attr_reader :deploy, :deployer, :maintainers
  
  def deliver!
    messages = maintainers.map do |maintainer|
      ProjectNotification.maintainer_of_deploy(maintainer, deploy).deliver!
    end
    
    if we_know_who_triggered_the_deploy and it_wasnt_a_maintainer
      messages << ProjectNotification.maintainer_of_deploy(deployer, deploy).deliver!
    end
    
    messages
  end
  
private
  
  def we_know_who_triggered_the_deploy
    !deployer.blank?
  end
  
  def it_wasnt_a_maintainer
    !maintainers.with_email_address(deployer).exists?
  end
  
end
