class Environment < ActiveRecord::Base
  
  belongs_to :project
  has_many :releases, :dependent => :destroy
  
  def to_param
    slug
  end
  
  def last_commit
    last_release = releases.first
    last_release ? last_release.commit1 : initial_commit
  end
  
  def resulting_kanban_field_id
    case slug # <-- NB! knowledge about environments
    when "dev"; project.testing_id
    when "master"; project.production_id
    else; nil
    end
  end
  
  
end
