class User < ActiveRecord::Base
  include Retirement
  
  has_many :testing_notes
  has_many :roles, :dependent => :destroy
  has_many :credentials, :class_name => "UserCredentials", :dependent => :destroy
  has_many :consumer_tokens
  has_and_belongs_to_many :commits
  
  serialize :environments_subscribed_to, JSON
  serialize :view_options, ActiveRecord::Coders::Hstore
  
  devise *Houston.config.devise_configuration
  
  attr_accessible :first_name, :last_name, :email,
                  :role, :password, :password_confirmation, :remember_me,
                  :environments_subscribed_to, :view_options, :alias_emails
  
  default_scope order("last_name, first_name")
  
  default_value_for :role, Houston.config.default_role
  
  validates :first_name, :last_name, :email, :presence => true, :length => {:minimum => 2}
  validates :role, :presence => true, :inclusion => Houston.config.roles
  validate :all_email_addresses_must_be_unique
  
  
  
  Houston.config.project_roles.each do |role|
    method_name = role.downcase.gsub(' ', '_')
    collection_name = method_name.pluralize
    
    class_eval <<-RUBY
    def self.#{collection_name}
      Role.#{collection_name}.to_users
    end
    RUBY
  end
  
  Houston.config.roles.each do |role|
    method_name = role.downcase.gsub(' ', '_')
    collection_name = method_name.pluralize
    
    class_eval <<-RUBY
    def self.#{collection_name}
      where(role: "#{role}")
    end
    
    def #{method_name}?
      role == "#{role}"
    end
    RUBY
  end
  
  
  def self.administrators
    where(administrator: true)
  end
  
  
  def self.participants
    Role.participants.to_users
  end
  
  def self.notified_of_releases_to(environment_name)
    where(["users.environments_subscribed_to LIKE ?", "%#{environment_name.inspect}%"])
  end
  
  def self.with_primary_email(email)
    email = email.downcase if email
    where(email: email)
  end
  
  def self.with_email_address(*email_addresses)
    values = email_addresses.flatten.map { |email| quote_value(email.downcase) }.join(",")
    where("ARRAY[\"email_addresses\"] && ARRAY[#{values}]")
  end
  
  
  
  def email=(value)
    value = value.downcase if value
    super(value)
    self.email_addresses = [email] + alias_emails
  end
  
  def email_addresses
    super || []
  end
  
  def alias_emails
    email_addresses - [email]
  end
  
  def alias_emails=(value)
    self.email_addresses = [email] + Array.wrap(value)
  end
  
  
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def environments_subscribed_to
    super || []
  end
  
  def follows?(project)
    roles.to_projects.member?(project)
  end
  
  
  
  # LDAP Overrides
  # ------------------------------------------------------------------------- #
  
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
  
  # ------------------------------------------------------------------------- #
  
  
  
private
  
  def all_email_addresses_must_be_unique
    email_addresses.each do |email_address|
      if User.where(User.arel_table[:id].not_eq(id)).with_email_address(email_address).any?
        errors.add :base, "The email address \"#{email_address}\" is being used"
      end
    end
  end
  
end
