module CommitSynchronizer
  
  
  def sync!
    repo.refresh!
  end
  
  
private
  
  def repo
    project.repo
  end
  
  def project
    proxy_association.owner
  end
  
end
