# Houston.config.authentication_strategy :ldap do
#   host "10.5.3.100"
#   port 636
#   ssl :simple_tls
#   base "dc=cph, dc=pri"
#   field "samaccountname"
#   username_builder Proc.new { |attribute, login, ldap| "#{login}@cph.pri" }
# end
