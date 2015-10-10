module Houston

  # When the git:post_receive hook is triggered, a commit range of
  # 0000000000000000000000000000000000000000...10fb27e indicates the creation of a branch, while
  # 10fb27e...0000000000000000000000000000000000000000 indicates the deletion of a branch
  NULL_GIT_COMMIT = "0000000000000000000000000000000000000000".freeze


end
