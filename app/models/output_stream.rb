class OutputStream

  def initialize(deploy)
    @deploy = deploy
    @lines = Concurrent::Array.new
  end

  def <<(value)
    @lines.push(value)
    begin
      @deploy.update_column :output, to_s
    rescue exceptions_wrapping(PG::ConnectionBad)
      # Be lazy about writing this to the database
      # Better yet, !todo, debounce this
      Rails.logger.warn "#{$!.class}: #{$!.message}"
    end
    self
  end

  def to_s
    @lines.join
  end

end
