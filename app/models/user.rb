class User < ActiveRecord::Base
  include Retirement
  include Houston::Props

  ROLES = %w{Owner Admin Member}.freeze

  has_many :roles, class_name: "TeamUser", dependent: :destroy
  has_and_belongs_to_many :teams
  has_many :authorizations, dependent: :destroy
  has_many :triggers, class_name: "PersistentTrigger", dependent: :destroy
  belongs_to :current_project, class_name: "Project"

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :invitable

  default_scope { order("last_name, first_name") }

  validates :first_name, :last_name, :email, :presence => true, :length => {:minimum => 2}
  validates :role, presence: true, inclusion: {in: ROLES, message: "%{value} is not one of the configured roles (#{ROLES.join(", ")})"}
  validate :all_email_addresses_must_be_unique



  ROLES.each do |role|
    method_name = role.downcase.gsub(" ", "_")
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



  def self.with_primary_email(email)
    email = email.downcase if email
    where(email: email)
  end

  def self.with_email_address(*email_addresses)
    email_addresses = email_addresses.flatten.compact
    return none if email_addresses.none?
    where ["email_addresses && ARRAY[?]", email_addresses.map(&:downcase)]
  end

  def self.find_by_email_address(email_address)
    with_email_address(email_address).first
  end

  def email=(value)
    value = value.downcase if value
    super(value)
    self.email_addresses = [email] + alias_emails
  end

  def email_addresses
    (super || []).reject(&:blank?)
  end

  def alias_emails
    email_addresses - [email]
  end

  def alias_emails=(value)
    self.email_addresses = [email] + Array.wrap(value).reject(&:blank?)
  end



  def name
    "#{first_name} #{last_name}"
  end

  def follows?(project)
    Role.where(user: self).to_projects.member?(project)
  end

  def followed_projects
    Role.where(user: self).to_projects.unretired
  end



private

  def all_email_addresses_must_be_unique
    email_addresses.each do |email_address|
      if User.where(User.arel_table[:id].not_eq(id)).with_email_address(email_address).any?
        errors.add :base, "The email address \"#{email_address}\" is being used"
      end
    end
  end

end
