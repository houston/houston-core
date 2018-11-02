class ApiToken < ActiveRecord::Base
  has_secure_token :value

  belongs_to :user

  validates :user_id, :name, :value, presence: true

  before_validation :generate_value, on: :create

  attr_readonly :user_id

private

  def generate_value
    self.value = ApiToken.generate_unique_secure_token
  end

end
