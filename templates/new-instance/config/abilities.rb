# This block uses the DSL defined by CanCan.
# https://github.com/ryanb/cancan/wiki/Defining-Abilities

Houston.config.abilities do |user|
  if user.nil?

    # Customers are allowed to see Release Notes of products, for production
    can :read, Release do |release|
      release.project.category == "Products" && (release.environment_name.blank? || release.environment_name == "production")
    end

    # Customers are allowed to see Features, Improvements, and Bugfixes
    can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

  else

    # Everyone can see Releases to staging
    can :read, Release

    # Everyone is allowed to see Features, Improvements, and Bugfixes
    can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

    # Everyone can see Projects
    can :read, Project

    # Everyone can see Tickets
    can :read, Ticket

    # Everyone can see Milestones
    can :read, Milestone

    # Everyone can see Users and update themselves
    can :read, User
    can :update, user

    # Everyone can make themselves a "Follower"
    can :create, Role, name: "Follower"

    # Everyone can remove themselves from a role
    can :destroy, Role, user_id: user.id

    # Developers can
    #  - create tickets
    #  - see other kinds of Release Changes (like Refactors)
    #  - update Sprints
    #  - break tickets into tasks
    if user.developer?
      can :read, [Commit, ReleaseChange]
      can :manage, Sprint
      can :manage, Task
    end

    # Testers and Developers can
    #  - create tickets
    #  - see and manage alerts
    if user.tester? or user.developer?
      can :create, Ticket
      can :manage, Houston::Alerts::Alert
    end

    # The following abilities are project-specific and depend on one's role
    roles = user.roles.participants
    if roles.any?

      # Maintainers can manage Releases, close Tickets, and update Projects
      roles.maintainers.pluck(:project_id).tap do |project_ids|
        can :manage, Release, project_id: project_ids
        can :close, Ticket, project_id: project_ids
        can :update, Project, id: project_ids
      end
    end
  end
end
