require "thread_safe"

class OutputStream
  
  def initialize(deploy)
    @deploy = deploy
    @lines = ThreadSafe::Array.new
  end
  
  def <<(value)
    @lines.push(value)
    @deploy.update_column :output, to_s
    self
  end
  
  def to_s
    @lines.join
  end
  
end
