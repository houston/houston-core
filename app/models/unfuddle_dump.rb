module UnfuddleDump
  extend self
  
  
  
  def path
    @path ||= Rails.root.join("tmp", "unfuddle_tickets.json")
  end
  
  def exists?
    File.exists?(path)
  end
  
  def delete!
    File.delete(path)
  end
  
  def last_updated
    File.mtime(path) if exists?
  end
  
  def last_updated_time
    exists? ? File.mtime(path).to_f : 0.0
  end
  
  def age
    (Time.now.to_f - last_updated_time).seconds
  end
  
  def fresh?
    age < 1.day
  end
  
  def load!
    download! unless fresh?
    return [] unless exists?
    read
  end
  
  def download!
    UnfuddleTicketDownloadJob.start!
  end
  
  def read
    JSON.load File.read(path)
  end
  
  
  
end
