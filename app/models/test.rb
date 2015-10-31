class Test < ActiveRecord::Base

  belongs_to :project
  has_many :test_results

  validates :project_id, :suite, :name, presence: true

  def introduced_in_shas
    test_results.where(new_test: true).joins(:test_run).pluck("test_runs.sha")
  end

end
