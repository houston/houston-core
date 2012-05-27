class ReleasePresenter
  
  def initialize(releases)
    @releases = releases
  end
  
  def as_json(*args)
    if @releases.is_a?(Release)
      to_hash @releases
    else
      @releases.map(&method(:to_hash))
    end
  end
  
  def to_hash(release)
    { id: release.id,
      createdAt: release.created_at }
  end
  
end
