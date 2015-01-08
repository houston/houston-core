class Measurement < ActiveRecord::Base
  
  belongs_to :subject, polymorphic: true
  
  validates :name, :value, :taken_at, presence: true
  validates :name, length: { maximum: 50 }
  
  default_scope -> { order(arel_table[:taken_at].desc) }
  
  class << self
    def take!(attributes)
      required_keys = [:subject_type, :subject_id, :taken_at, :name].freeze
      
      identifying_attributes = attributes.pick(required_keys)
      subject = attributes[:subject]
      identifying_attributes.merge!(subject_type: subject.class.name, subject_id: subject.id) if subject
      identifying_attributes.reverse_merge!(subject_type: nil, subject_id: nil)
      
      required_keys.each do |key|
        raise ArgumentError, "#{key.inspect} is required to take a measurement" unless identifying_attributes.key?(key)
      end
      
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
    
    def taken_after(date)
      where(arel_table[:taken_on].gteq(date))
    end
    
    def taken_between(date0, date1)
      taken_after(date0).taken_before(date1)
    end
    
    def for(subject)
      return where(subject_type: nil, subject_id: nil) if subject.nil?
      where(subject_type: subject.class.name, subject_id: subject.id)
    end
    
    def global
      self.for(nil)
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
        .gsub(/\{([\w,]+)\}/) { "(#{$~.captures[0].gsub(/,/, "|")})" }
        .gsub(/\.\*$/, "%") }
      where(["name SIMILAR TO ?", "(#{name_patterns.join("|")})"])
    end
    
    def total
      pluck(:value).inject(0) { |sum, value| sum + value.to_d }
    end
    
    def value
      limit(1).pluck(:value)[0]
    end
    
    def mean
      denominator = count
      return nil if denominator.zero?
      total.to_f / denominator
    end
    
    def debug(colored: true)
      format_subject = ->(s) { s.is_a?(User) ? s.first_name : s.is_a?(Project) ? s.slug : "" }
      includes(:subject).reorder("taken_at ASC, subject_type ASC, subject_id ASC, name ASC").map { |m|
        line = [ m.taken_on.strftime("%-m/%-d").rjust(5),
                 m.taken_at.strftime("%H:%M:%S"),
                 format_subject[m.subject].ljust(9),
                 m.name.ljust(50),
                 m.value.rjust(8) ].join(" ")
        line = "\e[36m#{line}\e[0m" if colored && m.subject_type == "User"
        line = "\e[35m#{line}\e[0m" if colored && m.subject_type == "Project"
        line }.join("\n")
    end
  end
  
  def taken_at=(value)
    super
    self.taken_on = value && value.to_date
  end
  
end
