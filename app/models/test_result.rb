class TestResult < ActiveRecord::Base

  belongs_to :test
  belongs_to :test_run
  belongs_to :error, class_name: "TestError"

  validates :test_id, :test_run_id, presence: true
  validates :status, inclusion: {in: %w{fail skip pass}}

  def self.insert_many(attributes)
    return if attributes.none?
    columns = attributes.first.keys
    values = attributes.map(&:values)
    import columns, values, validate: false
  end

end
