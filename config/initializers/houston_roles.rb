module Houston
  
  def self.roles
    # The Team view is sorted in the order these roles appear
    [ "Developer",
      "Tester",
      "Product Owner",
      "Guest" ]
  end
  
  def self.default_role
    "Guest"
  end
  
end
