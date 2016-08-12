Houston.register_events {{

  "commit:create"                   => params("commit").desc("A new commit was created"),

  "daemon:{type}:start"             => desc("Daemon {type} has started"),
  "daemon:{type}:restart"           => desc("Daemon {type} has restarted"),
  "daemon:{type}:stop"              => desc("Daemon {type} has stopped"),

  "deploy:completed"                => params("deploy").desc("A deploy just finished"),
  "deploy:succeeded"                => params("deploy").desc("A deploy succeeded"),
  "deploy:failed"                   => params("deploy").desc("A deploy failed"),

  "github:comment:create"           => params("comment").desc("A comment was added to a commit, diff, or issue on GitHub"),
  "github:comment:{type}:create"    => params("comment").desc("A comment was added to a {type} on GitHub"),
  "github:comment:update"           => params("comment").desc("A comment on a commit, diff, or issue was updated on GitHub"),
  "github:comment:{type}:update"    => params("comment").desc("A comment on a {type} was updated on GitHub"),
  "github:comment:delete"           => params("comment").desc("A comment on a commit, diff, or issue was deleted on GitHub"),
  "github:comment:{type}:delete"    => params("comment").desc("A comment on a {type} was deleted on GitHub"),

  "github:pull:opened"              => params("pull_request").desc("A pull request was opened"),
  "github:pull:updated"             => params("pull_request", "changes").desc("A pull request was updated"),
  "github:pull:closed"              => params("pull_request").desc("A pull request was closed"),
  "github:pull:reopened"            => params("pull_request").desc("A pull request was reopened"),
  "github:pull:synchronize"         => params("pull_request").desc("Commits where pushed to a pull request"),

  "hooks:{type}"                    => params("params").desc("/hooks/{type} was invoked"),
  "hooks:project:{type}"            => params("project", "params").desc("/hooks/project/:slug/{type} was invoked"),

  "release:create"                  => params("release").desc("A new release was created"),

  "task:released"                   => params("task").desc("A commit mentioning this task was released"),
  "task:committed"                  => params("task").desc("A commit mentioning this task was created"),
  "task:completed"                  => params("task").desc("A task was completed"),
  "task:reopened"                   => params("task").desc("A task was reopened"),

  "test_run:start"                  => params("test_run").desc("A test run was started on the CI server"),
  "test_run:complete"               => params("test_run").desc("A test run was completed on the CI server"),
  "test_run:compared"               => params("test_run").desc("The test results for a commit were compared to the results for its parent"),

  "ticket:release"                  => params("ticket", "release").desc("A ticket was released")

}}
