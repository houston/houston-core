class ConvertProjectExtendedAttributesToProps < ActiveRecord::Migration
  def up
    add_column :projects, :props, :jsonb, default: "{}"

    require "progressbar"
    projects = Project.all
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      props = project.read_attribute(:extended_attributes) || {}
      props.merge!(project.read_attribute(:view_options) || {})

      props["unfuddle.projectId"] = props.delete("unfuddle_project_id") if props.key?("unfuddle_project_id")
      props["errbit.appId"] = props.delete("errbit_app_id") if props.key?("errbit_app_id")
      props["github.repo"] = props.delete("github_repo") if props.key?("github_repo")
      props["git.location"] = props.delete("git_location") if props.key?("git_location")

      props.keys.each do |old_key|
        next unless dependency_name = old_key[/^key_dependency\.(.*)$/, 1]
        new_key = "keyDependency.#{dependency_name}"
        props[new_key] = props.delete(old_key)
      end

      project.update_column :props, props
      pbar.inc
    end
    pbar.finish
  end

  def down
    remove_column :projects, :props
  end
end
