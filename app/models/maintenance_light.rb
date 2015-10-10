class MaintenanceLight

  def initialize(dependency, color, message)
    @version = dependency.version
    @dependency_name = dependency.name
    @color = color
    @message = message
  end

  attr_reader :version, :dependency_name, :color, :message

end
