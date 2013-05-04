# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


Project.destroy_all


unite = Project.create(
  name: "Unite",
  slug: "unite",
  color: "teal",
  ticket_tracker_name: "Unfuddle",
  extended_attributes: {"unfuddle_project_id" => "25"})



tsatsiki = Project.create(name: "Tsatsiki", slug: "tsatsiki", color: "blue", version_control_location: "git://github.com/boblail/tsatsiki.git")

tsatsiki_release1 = tsatsiki.releases.create(
  name: "Upgrade Rails to 3.1",
  environment_name: "Production",
  commit0: "8e0f2f6d32cfcbd2ee39a10da1dc568e9dcb30d1",
  commit1: "7cb53278a8f3577f43c38335793d88b992715839")
tsatsiki_release1.load_commits!
tsatsiki_release2 = tsatsiki.releases.create(
  name: "Specification",
  environment_name: "Production",
  commit0: "7cb53278a8f3577f43c38335793d88b992715839",
  commit1: "d3d1e7d9b40292071016b19fded67d051bf38615")
tsatsiki_release2.load_commits!



houston = Project.create(name: "Houston", slug: "houston", color: "red", version_control_location: Rails.root.to_s)


church_360 = Project.create(
  name: "Church360",
  slug: "360",
  color: "orange",
  ticket_tracker_name: "Unfuddle",
  extended_attributes: {"unfuddle_project_id" => "1"})




admin = User.create(
  first_name: "Example",
  last_name: "User",
  email: "user@example.com",
  password: "password",
  role: "Developer")
admin.update_attribute(:administrator, true)
