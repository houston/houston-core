require "github/comment_event"

module Github
  class CommitCommentEvent < CommentEvent
    self.type = "commit"
  end
end
