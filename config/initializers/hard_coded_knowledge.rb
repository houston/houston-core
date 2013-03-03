# Eventually we should get rid of this, of course.
# But, for now, this file documents a few things 
# we've scattered throughout the code base and need
# to abstract.
module Houston
  module TMI
    
    EXTENDED_ATTRIBUTES = [:estimated_effort, :estimated_value, :unable_to_set_estimated_effort, :unable_to_set_estimated_value]
    NAME_OF_DEPLOYMENT_FIELD = "Fixed in"
    NAME_OF_GOLDMINE_FIELD = "Goldmine"
    FIELD_USED_FOR_LDAP_LOGIN = "samaccountname"
    INSTRUCTIONS_FOR_LOGIN = "You can log in with your CPH domain account"
    
  end
end
