class SyncCommitsJob

  def self.run!
    new.run!
  end

  def run!
    Project.unretired.find_each do |project|
      project.commits.sync!
    end
  end

end
