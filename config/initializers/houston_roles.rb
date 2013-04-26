module Houston
  
  def self.project_roles
    # The roles a user can have in a project
    [ "Owner",
      "Maintainer",
      "Contributor",
      "Tester",
      "Follower" ]
  end
  
  def self.roles
    # The Team view is sorted in the order these roles appear
    [ "Developer",
      "Tester",
      "Guest" ]
  end
  
  def self.default_role
    "Guest"
  end
  
end
