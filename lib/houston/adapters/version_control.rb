require "houston/adapters"

Houston::Adapters.define_adapter_namespace "VersionControl"

require "houston/adapters/version_control/commit"
require "houston/adapters/version_control/errors"
