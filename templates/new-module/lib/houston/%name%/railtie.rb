module Houston
  module <%= camelized %>
    class Railtie < ::Rails::Railtie

      # The block you pass to this method will run for every request
      # in development mode, but only once in production.
      # config.to_prepare do
      # end

    end
  end
end
