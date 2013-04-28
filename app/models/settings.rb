class Settings
  
  def initialize(attributes={})
    attributes.each do |key, value|
      self[key] = value
    end
  end
  
  def [](name)
    fetch(name, nil)
  end
  
  def fetch(name, *args)
    setting = settings.find { |setting| setting.name == name }
    return setting.value if setting
    raise KeyError, "key not found: #{name.inspect}" if args.empty?
    args.first
  end
  
  def []=(name, value)
    setting = settings.find { |setting| setting.name == name }
    settings << (setting = Setting.new(name: name)) unless setting
    setting.value = value
  end
  
  def save!
    settings.each do |setting|
      setting.save if setting.changed?
    end
  end
  
private
  
  def settings
    @settings ||= Setting.all
  end
  
end
