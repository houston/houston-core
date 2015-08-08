class Test < ActiveRecord::Base

  belongs_to :project

  validates :project_id, :suite, :name, presence: true

end
