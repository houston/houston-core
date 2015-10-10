module Rubygems
  class Error < RuntimeError; end

  class Gem

    def initialize(name, options={})
      @name = name
      @include_prerelease = options.fetch(:prerelease, false)
    end

    attr_reader :name
    alias_method :to_s, :name

    delegate :cache_key,
             :request_releases_of,
             :to => "self.class"



    def self.request_releases_of(name)
      response = Houston.benchmark title: "GET rubygems.org" do
        Faraday.get("https://rubygems.org/api/v1/versions/#{name}.json")
      end
      raise Rubygems::Error, "Unexpected response from rubygems. Status: #{response.status}" unless response.status == 200

      MultiJson.load(response.body)
    rescue Faraday::Error::ConnectionFailed
      raise Rubygems::Error, "Unable to connect to rubygems.org: #{$!.message}"
    end

    def self.cache_key(name, date)
      "rubygems/#{name}/releases/#{date.strftime('%Y%m%d')}/json"
    end



    def releases
      fetch_releases_from_previous_cache_on_error do
        key = cache_key(name, Date.today)
        Rails.cache.fetch(key) { request_releases_of(name) }
      end
    end

    def versions
      @versions ||= begin
        versions = releases.map { |release| ::Gem::Version.new(release["number"]) }
        versions = versions.reject(&:prerelease?) unless @include_prerelease
        versions.sort.reverse
      end
    end



    def fetch_releases_from_previous_cache_on_error
      yield
    rescue Rubygems::Error
      Rails.logger.error "[rubygems] an error occurred fetching releases for '#{name}': #{$!}"
      Houston.report_exception $!

      # Have we cached releases any time in the last month?
      (1..30).each do |n|
        date = n.days.ago
        key = cache_key(name, date)
        if Rails.cache.exist?(key)
          Rails.logger.info "[rubygems] using releases of '#{name}' cached on #{date}"
          return Rails.cache.fetch(key)
        end
      end

      []
    end



  end
end
