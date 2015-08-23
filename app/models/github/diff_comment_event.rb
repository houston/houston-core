require "github/comment_event"

module Github
  class DiffCommentEvent < CommentEvent
    self.type = "diff"
  end
end
