class User < ActiveRecord::Base
  
  # Include default devise modules. Others available are:
  #      :token_authenticatable,
  #      :registerable,
  #      :encryptable,
  #      :confirmable,
  #      :lockable,
  #      :timeoutable,
  #      :omniauthable
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :invitable
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :role, :password, :password_confirmation, :remember_me
  
  ROLES = %w{Developer Stakeholder Tester}
  
  validates :name, :presence => true, :uniqueness => true
  validates :role, :presence => true, :inclusion => ROLES
  
end
