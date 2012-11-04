class Tag < ActiveRecord::Base
  self.table_name = "change_tags"
  
  validates :color,
    :presence => true
  validates :name,
    :presence => true,
    :length => {:minimum => 1},
    :uniqueness => true
  
  before_validation :assign_a_default_color
  
  
  def self.find_or_create_from_slug(slug)
    return nil unless slug
    self.find_or_create_by_name(slug.titleize)
  end
  
  
  def assign_a_default_color
    self.color ||= Houston.config.colors.values.sample.to_s
  end
  
  
end
