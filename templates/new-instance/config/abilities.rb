# This block uses the DSL defined by CanCan.
# https://github.com/ryanb/cancan/wiki/Defining-Abilities

Houston.config do


  role "Maintainer" do |team|

    # Maintainers can create releases
    can :manage, Houston::Releases::Release, project_id: team.project_ids

    # Maintainers can change projects' settings
    can :update, Project, id: team.project_ids

  end


  role "Developer" do |team|

    # Developers can see commits and can manage
    # tickets, pull requests, and alerts
    can :read, Commit, project_id: team.project_ids
    can :manage, Task, project_id: team.project_ids
    can :create, Ticket, project_id: team.project_ids
    can :close, Ticket, project_id: team.project_ids
    can :manage, Github::PullRequest, project_id: team.project_ids
    can :manage, Houston::Alerts::Alert, project_id: team.project_ids

  end


  role "Tester" do |team|

    # Testers can create tickets and be assigned Alerts
    can :create, Ticket, project_id: team.project_ids
    can :manage, Houston::Alerts::Alert, project_id: team.project_ids

  end


  abilities do |user|
    if user.nil?

      # Customers are allowed to see Release Notes of products, for production
      can :read, Houston::Releases::Release do |release|
        release.environment_name == "production"
      end

    else

      if user.admin?

        # Admins can see Actions
        can :read, Action

      end

      # Employees can see Teams
      can :read, Team

      # Employees can see Releases to staging
      can :read, Houston::Releases::Release

      # Employees can see Projects
      can :read, Project

      # Employees can see Tickets
      can :read, Ticket

      # Employees can see Roadmaps
      can :read, Roadmap
      can :read, Milestone

      # Employees can see Users and update themselves
      can :read, User
      can :update, user

      # Employees can read and tag and create feedback
      can :read, Houston::Feedback::Comment
      can :tag, Houston::Feedback::Comment
      can :create, Houston::Feedback::Comment

      # Employees can update their own feedback
      can [:update, :destroy], Houston::Feedback::Comment, user_id: user.id

    end
  end
end
