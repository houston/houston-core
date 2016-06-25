class ProjectPresenter
  include UrlHelper

  def initialize(projects)
    @projects = OneOrMany.new(projects)
  end

  def as_json(*args)
    projects = @projects
    projects = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
      projects.load
    end if projects.is_a?(ActiveRecord::Relation)
    Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
      projects.map(&method(:project_to_json))
    end
  end

  def project_to_json(project)
    { id: project.id,
      name: project.name,
      slug: project.slug,
      color: {
        name: project.color,
        hex: project.color_value.hex },
      props: project.props.to_h }
  end

end
