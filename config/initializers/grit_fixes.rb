# Extensions that are monkey-patched into Grit for convenience.

# Several methods (Commit#message, Actor#name, Actor#email) are monkey-patched to force
# UTF-8 encoding. This is because grit will return ASCII-8BIT strings (essentially a binary
# byte sequence) for these fields, and this causes problems because Ruby 1.9 won't let you
# concatenate these with UTF-8 strings unless the ASCII-8BIT string has no byte values > 128.

require "grit"

module Grit
  class Commit
    alias_method :message_original, :message
    def message
      message_original.force_encoding("utf-8")
    end
  end
  
  class Actor
    alias_method :name_original, :name
    def name
      name_original.force_encoding("utf-8")
    end
    
    alias_method :email_original, :email
    def email
      email_original.force_encoding("utf-8")
    end
  end
end
