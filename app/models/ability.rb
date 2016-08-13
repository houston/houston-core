class Ability
  include CanCan::Ability



  def initialize(user)
    if user

      # Owners can do everything

      if user.owner?
        can :manage, :all
        return
      end

      # Admins can create teams

      if user.admin?
        can [:read, :create], Team
      end

      # Users get abilities based on their role
      # in any teams they are members of

      user.roles.each do |role|
        Houston.config.configure_team_abilities(self, role)
      end
    end

    if Houston.config.defines_abilities?
      Houston.config.configure_abilities(self, user)
    else
      default_abilities_for(user)
    end
  end



  def default_abilities_for(user)
    return unless user

    # If you're logged in, you can see everything
    can :read, :all

    # If you're logged in, you can update yourself
    can :update, user
  end



end
