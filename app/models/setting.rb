class Setting < ActiveRecord::Base

  validates_presence_of :name, :value

  def self.[](name)
    setting = where(name: name).first
    setting && setting.value
  end

end
