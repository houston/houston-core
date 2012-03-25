class Project < ActiveRecord::Base
  
  has_many :environments, :dependent => :destroy
  
  accepts_nested_attributes_for :environments, :allow_destroy => true
  
  
  
  def to_param
    slug
  end
  
  
  
  def git_path
    @git_path ||= get_local_git_path
  end
  
  def git_uri
    @git_uri ||= URI(git_url)
  end
  
  def temp_path
    @temp_path ||= Rails.root.join("tmp", slug).to_s
  end
  
  
  
  def repo
    @repo ||= Grit::Repo.new(git_path)
  end
  
  
  
private
  
  
  
  def get_local_git_path
    if git_uri.absolute?
      get_local_copy_of_project!
      temp_path
    else
      git_uri
    end
  end
  
  def get_local_copy_of_project!
    if File.exists?(temp_path)
      git_pull!
    else
      git_clone!
    end
  end
  
  def git_pull!
    `cd "#{temp_path}" && git pull origin master`
  end
  
  def git_clone!
    `cd "#{Rails.root.join("tmp").to_s}" && git clone #{git_url} ./#{slug}`
  end
  
  
  
end
