class MeasurementsPresenter
  attr_reader :measurements

  def initialize(measurements)
    @measurements = measurements
  end

  def to_json(*args)
    Houston.benchmark "[#{self.class.name.underscore}] Render JSON" do
      query = measurements.select(<<-SQL)
        id,
        (taken_at AT TIME ZONE 'UTC') AT TIME ZONE '#{Time.zone.now.strftime("%Z")}' "timestamp",
        name,
        value,
        json_build_object('type', subject_type, 'id', subject_id) "subject"
      SQL

      ActiveRecord::Base.connection.select_value("select array_to_json(array_agg(row_to_json(t))) from (#{query.to_sql}) t") || []
    end
  end

end
