class SyncCommitsJob
  
  def self.run!
    new.run!
  end
  
  def run!
    Project.find_each do |project|
      project.commits.sync!
    end
  end
  
end
