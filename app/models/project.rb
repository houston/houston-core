class Project < ActiveRecord::Base
  include ::Project::Unfuddle
  
  has_many :environments, :dependent => :destroy
  has_many :tickets, :dependent => :destroy
  
  accepts_nested_attributes_for :environments, :allow_destroy => true
  
  
  
  def in_development_query
    "#{kanban_field}-eq-#{development_id}"
  end
  
  def staged_for_testing_query
    "#{kanban_field}-eq-#{development_id}"
  end
  
  def in_testing_query
    "#{kanban_field}-eq-#{testing_id}"
  end
  
  def staged_for_release_query
    "#{kanban_field}-neq-#{production_id}"
  end
  
  
  
  def tickets_in_queue(queue)
    case queue.to_sym
    when :staged_for_development
      []
    
    when :in_development
      find_tickets(in_development_query, :status => :accepted)
    
    when :staged_for_testing
      find_tickets(staged_for_testing_query, :status => :resolved)
    
    when :in_testing
      find_tickets(in_testing_query, :status => :resolved)
    
    when :staged_for_release
      find_tickets(staged_for_release_query, :status => :closed, :resolution => :fixed)
    
    when :last_release
      []
    end
  end
  
  
  
  def to_param
    slug
  end
  
  
  
  def git_path
    @git_path ||= get_local_git_path
  end
  
  def git_uri
    @git_uri ||= Addressable::URI.parse(git_url)
  end
  
  def temp_path
    @temp_path ||= Rails.root.join("tmp", slug).to_s
  end
  
  
  
  def repo
    @repo ||= Grit::Repo.new(git_path)
  end
  
  
  
private
  
  
  
  # Git repositories can be located on the local
  # machine (e.g. /path/to/repo) or they can be
  # located on remotely (e.g. git@host:repo.git).
  #
  # If the repo is local, we don't need to check
  # out a copy. If it is remote, we want to clone
  # it to a temp folder and then manipulate it.
  #
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
