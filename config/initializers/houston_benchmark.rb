module Houston

  def self.benchmark(title, &block)
    if Rails.env.development? || !defined?(Skylight)
      ActiveRecord::Base.benchmark "\e[33m#{title}\e[0m", &block
    else
      Skylight.instrument title: title, &block
    end
  end

end
