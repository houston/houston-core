class Test < ActiveRecord::Base

  belongs_to :project
  has_many :test_results

  validates :project_id, :suite, :name, presence: true

end
