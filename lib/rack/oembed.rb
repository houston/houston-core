module Rack
  class Oembed
    attr_reader :app, :oembed_path

    def initialize(app, options={})
      @app = app
      @oembed_path = options.fetch :path
      @oembed_path = "/#{oembed_path}" unless oembed_path.starts_with? "/"
    end

    def call(env)
      if env["REQUEST_METHOD"] == "GET" && env["PATH_INFO"] == oembed_path
        url = Rack::Request.new(env).params.fetch("url")
        path = Addressable::URI.parse(url).path
        env["PATH_INFO"] = path
        env["HTTP_ACCEPT"] = "application/json+oembed"
      end

      app.call(env)
    end

  end
end
