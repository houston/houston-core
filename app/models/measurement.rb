class Measurement < ActiveRecord::Base
  
  belongs_to :subject, polymorphic: true
  
  validates :name, :value, :taken_at, presence: true
  
  default_scope -> { order(arel_table[:taken_at].desc) }
  
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
    
    def taken_before(date)
      where(arel_table[:taken_on].lteq(date))
    end
    
    def for(subject)
      where(subject_type: subject.class.name, subject_id: subject.id)
    end
    
    # Valid identifies for names
    #  - weekly.hours.charged
    #  - weekly.hours.charged.*
    #  - weekly.hours.charged.{fix,chore}
    #  - weekly.hours.{worked,charged}.fix
    # Invalid arguments
    #  - weekly.hours.*.fix
    def named(*name_patterns)
      name_patterns =  name_patterns.flatten.map { |pattern| pattern
        .gsub(/\{(?:(\w+),)+(\w+)\}/) { "(#{$~.captures.join("|")})" }
        .gsub(/\.\*$/, "%") }
      where(["name SIMILAR TO ?", "(#{name_patterns.join("|")})"])
    end
    
    def total
      pluck(:value).inject(0) { |sum, value| sum + value.to_d }
    end
    
    def mean
      denominator = count
      return nil if denominator.zero?
      total.to_f / denominator
    end
  end
  
  def taken_at=(value)
    super
    self.taken_on = value && value.to_date
  end
  
end
