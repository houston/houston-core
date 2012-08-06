module UserHelper
  
  
  
  def users_by_role(users)
    users_by_role = users.group_by(&:role)
    User::ROLES.each do |role|
      users = users_by_role[role]
      yield role, users if users && users.any?
    end
  end
  
  
  
end
