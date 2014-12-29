class Measurement < ActiveRecord::Base
  
  belongs_to :subject, polymorphic: true
  
  validates :name, :value, :taken_at, presence: true
  
  default_scope -> { order(arel_table[:taken_at].asc) }
  
  class << self
    def take!(attributes)
      identifying_attributes = attributes.pick(:subject_type, :subject_id, :taken_at, :name)
      subject = attributes[:subject]
      identifying_attributes.merge!(subject_type: subject.class.name, subject_id: subject.id) if subject
      find_or_initialize_by(identifying_attributes).tap do |measurement|
        measurement.value = attributes[:value]
        measurement.save!
      end
    end
    
    def taken_at(time)
      where(taken_at: time)
    end
    
    def taken_on(date)
      where(taken_on: date)
    end
  end
  
  def taken_at=(value)
    super
    self.taken_on = value && value.to_date
  end
  
end
