class TestError < ActiveRecord::Base

  def output=(value)
    super value
    self.sha = Digest::SHA1.hexdigest(value)
  end

end
