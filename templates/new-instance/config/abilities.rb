# This block uses the DSL defined by CanCan.
# https://github.com/ryanb/cancan/wiki/Defining-Abilities

Houston.config do


  role "Maintainer" do |team|

    # Maintainers can change projects' settings
    can :update, Project, id: team.project_ids

  end


  abilities do |user|
    if user.nil?

      # Guests have no additional abilities

    else

      if user.admin?

        # Admins can see Actions
        can :read, Action

      end

      # All users can see Teams
      can :read, Team

      # All users  can see Projects
      can :read, Project

      # All users can see Users and update themselves
      can :read, User
      can :update, user

    end
  end
end
