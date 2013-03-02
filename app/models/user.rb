class User < ActiveRecord::Base
  
  has_many :testing_notes
  has_many :notifications, :class_name => "UserNotification", :uniq => true
  has_and_belongs_to_many :projects, :join_table => "projects_maintainers"
  
  after_create :save_default_notifications
  
  devise *Houston.config.devise_configuration
  
  attr_accessible :first_name, :last_name, :email,
                  :role, :password, :password_confirmation,
                  :remember_me, :notifications_pairs, :unfuddle_id
  
  ROLES = %w{Developer Tester Stakeholder Guest}
  
  default_scope order("last_name, first_name")
  
  default_value_for :role, "Guest"
  
  validates :first_name, :last_name, :email, :presence => true, :length => {:minimum => 2}
  validates :role, :presence => true, :inclusion => ROLES
  
  ROLES.each do |role|
    class_eval <<-RUBY
    def #{role.downcase}?
      role == "#{role}"
    end
    
    def self.#{role.downcase.pluralize}
      where(:role => "#{role}")
    end
    RUBY
  end
  
  
  
  def name
    "#{first_name} #{last_name}"
  end
  
  
  
  def notifications_pairs=(pairs)
    self.notifications = pairs.map do |pair|
      project_id, environment_name = pair.split(",")
      find_or_create_notification(project_id: project_id.to_i, environment_name: environment_name)
    end
  end
  
  
  
  def default_notifications_environments
    case role # <-- knowledge of environments
    when "Tester";      %w{Staging Production}
    when "Stakeholder"; %w{Production}
    else                []
    end
  end
  
  
  
  
  # LDAP Overrides
  
  def self.find_ldap_entry(ldap_connection, auth_key_value)
    filter = Net::LDAP::Filter.eq(Houston::TMI::FIELD_USED_FOR_LDAP_LOGIN, auth_key_value)
    ldap_connection.ldap.search(filter: filter).first
  end
  
  def self.find_for_ldap_authentication(attributes, entry)
    email = entry.mail.first.downcase
    user = where(email: email).first
  end
  
  def self.create_from_ldap_entry(attributes, entry)
    create!(
      email: entry.mail.first.downcase,
      password: attributes[:password],
      first_name: entry.givenname.first,
      last_name: entry.sn.first )
  end
  
  
  
protected
  
  
  def save_default_notifications
    environments = default_notifications_environments
    Project.all.each do |project|
      environments.each do |environment|
        self.notifications.push find_or_create_notification(project_id: project.id, environment_name: environment)
      end
    end
    nil
  end
  
  def find_or_create_notification(attributes)
    UserNotification.find_or_create(attributes.merge(user_id: id))
  end
  
  
end
