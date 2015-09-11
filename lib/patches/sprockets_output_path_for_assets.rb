# Sprockets 2.x constructs the path where assets are compiled to like this:
#
#   Rails.root + "public/assets"
#
# Rails.root is always the path to _this_ project, Houston Core.
#
# Sprockets 3.x constructs the path where assets are compiled to like this:
#
#  Rails.public_path + "assets"
#
# This is more desirable because Houston can configure the public path
# to be relative to the root of the instance of Houston. So we backport
# that change to Sprockets here.

require "sprockets/rails/task"

module Patches
  module SprocketsOutputPathForAssets
    def output
      if app
        File.join(app.paths["public"].first, app.config.assets.prefix)
      else
        super
      end
    end
  end
end

Sprockets::Rails::Task.send :prepend, Patches::SprocketsOutputPathForAssets
