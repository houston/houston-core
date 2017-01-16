Houston.register_events {{

  "daemon:{type}:start"             => desc("Daemon {type} has started"),
  "daemon:{type}:restart"           => desc("Daemon {type} has restarted"),
  "daemon:{type}:stop"              => desc("Daemon {type} has stopped"),

  "hooks:{type}"                    => params("params").desc("/hooks/{type} was invoked"),
  "hooks:project:{type}"            => params("project", "params").desc("/hooks/project/:slug/{type} was invoked")

}}
