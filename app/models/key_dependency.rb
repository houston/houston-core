class KeyDependency
  
  
  def self.versions
    @dependency_versions ||= {}.tap do |hash|
      
      Houston.config.key_dependencies.each do |dependency|
        hash[dependency] = Rails.cache.fetch "key_dependencies/#{dependency}/#{Date.today.strftime('%Y%m%d')}/info" do
          
          versions = Rubygems::Gem.new(dependency).versions
          next unless versions.any?
          
          stringified_versions = versions.map(&:to_s)
          latest_version = versions.first
          current_minor_version = stringified_versions.first[/\d+\.\d+/]
          rx = /^#{current_minor_version}\.\d+$/
          patches = stringified_versions.select { |version| version =~ rx }
          
          {
            name: dependency.titleize,
            versions: versions,
            minor_versions: stringified_versions.map { |version| version[/\d+\.\d+/] }.uniq,
            patches: patches,
            latest: latest_version
          }
          
        end
      end
      
    end
  end
  
  
end
