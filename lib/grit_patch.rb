require 'grit'

module Grit
  class Repo
    
    
    # The Commits objects that are reachable via +to+ but not via +from+
    # Commits are returned in chronological order.
    #   +from+ is the branch/commit name of the younger item
    #   +to+ is the branch/commit name of the older item
    #
    # Returns Grit::Commit[] (baked)
    def commits_between(from, to)
      
      # If from is blank, get all the commits reachable via +to+
      if from.blank?
        Commit.find_all(self, "#{to}").reverse
      else
        Commit.find_all(self, "#{from}..#{to}").reverse
      end
    end
    
    
  end
end
  