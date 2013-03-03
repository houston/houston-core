class Ability
  include CanCan::Ability
  
  def initialize(user)
    if user && user.administrator?
      can :manage, :all
    else
      Houston.config.configure_abilities(self, user)
    end
  end
  
end
