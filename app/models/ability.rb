class Ability
  include CanCan::Ability



  def initialize(user)
    if user && user.administrator?
      can :manage, :all
    elsif Houston.config.defines_abilities?
      Houston.config.configure_abilities(self, user)
    else
      default_abilities_for(user)
    end
  end



  def default_abilities_for(user)

    # Anyone can see everything
    can :read, :all

    if user

      # If you're logged in, you can update yourself
      can :update, user

      if user.developer?

        # Developers can manage projects and releases
        can :manage, Project
        can :manage, Release
        can :manage, Sprint

      end
    end

  end



end
