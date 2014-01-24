# Eventually we should get rid of this, of course.
# But, for now, this file documents a few things 
# we've scattered throughout the code base and need
# to abstract.
module Houston
  module TMI
    
    NAME_OF_GITHUB_ORGANIZATION = "concordia-publishing-house"
    NAME_OF_DEPLOYMENT_FIELD = "Fixed in"
    FIELD_USED_FOR_LDAP_LOGIN = "samaccountname"
    INSTRUCTIONS_FOR_LOGIN = "You can log in with your CPH domain account"
    TICKET_TYPES = %w{Feature Enhancement Bug Chore}
    TICKET_TYPE_COLORS = {
      nil           => "EFEFEF",
      "Chore"       => "98C221",
      "Feature"     => "3FC1AA",
      "Enhancement" => "EBD94B", # "FDDD32",
      "Bug"         => "D65B17"
    }
    TICKET_LABELS_FOR_MEMBERS = [
      'Admin',
      'Global',
      'What\'s New',
      'Help',
      'Feedback',
      'Overview',
      'Overview / Upcoming Events',
      'Overview / Notifcations',
      'Overview / Data Health',
      'Overview / Recent Attendance',
      'Reports',
      'Reports / Annual Report',
      'Trends',
      'Trends / Export',
      'Trends / Print',
      'Trends Detail',
      'Trends Detail / Export',
      'Trends Detail / Print',
      'People',
      'People / Export',
      'People / Print',
      'Profile',
      'Profile / Photo',
      'Profile / General',
      'Profile / Family',
      'Profile / Attendance',
      'Profile / Offering',
      'Profile / Notes',
      'Profile / Pastoral Visits',
      'Profile / Export',
      'Mailing Labels',
      'Church Directory',
      'Add/Remove Tags',
      'Send Email',
      'Contribution Statements',
      'Households',
      'Households / Export',
      'Households / Print',
      'Household',
      'Household / Photo',
      'Household / General',
      'Household / Members',
      'Household / Notes',
      'Household / Pastoral Visits',
      'Smart Groups',
      'Tags',
      'Pastoral Visits',
      'New Person',
      'New Person / vCard',
      'Events',
      'Events / Print',
      'Event',
      'Event / Anniversary',
      'Calendars',
      'Enter Attendance',
      'Enter Offerings',
      'Enter Offerings / Export',
      'Envelopes',
      'Funds',
      'Pledges',
      'Settings',
      'Logins',
      'Permisssions',
      'Sunday School',
      'SS Import'
    ]
    
  end
end
