class MeasurementsPresenter
  attr_reader :measurements

  def initialize(measurements)
    @measurements = measurements
  end

  def to_json(*args)
    Houston.benchmark "[#{self.class.name.underscore}] Render JSON" do
      MultiJson.dump(as_json(*args))
    end
  end

  def as_json(*args)
    Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
      measurements.pluck(:name, :taken_at, :value, :subject_type, :subject_id)
        .map do |name, timestamp, value, subject_type, subject_id|
        { timestamp: timestamp,
          name: name,
          value: value,
          subject: { type: subject_type, id: subject_id } }
      end
    end
  end

end
