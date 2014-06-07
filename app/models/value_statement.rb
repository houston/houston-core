class ValueStatement < ActiveRecord::Base
  
  versioned initial_version: true, dependent: :tracking, only: [:text, :weight]
  
  belongs_to :project
  validates :project_id, :weight, presence: true
  validates :text, length: 2..36
  
end
