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
      
      
      if user.developer? or user.tester?
        
        # Developers and Testers can see and comment on Testing Reports
        # They can also edit their own notes
        can [:create, :read], TestingNote
        can [:update, :destroy], TestingNote, user_id: user.id
        
      end
      
      
      if user.developer?
        
        # Developers can manage projects and releases
        can :manage, Project
        can :manage, Release
        
      end
    end
    
  end
  
  
  
end
