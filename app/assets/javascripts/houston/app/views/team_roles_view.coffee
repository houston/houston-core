class @Houston.TeamRolesView extends Houston.NestedResources
  resource: 'roles'
  viewPath: 'houston/teams/roles'

  initialize: (options)->
    @collection = new Houston.Roles(options.values, parse: true)
    super
    @options = options
    @templateOptions.roles = @options.roles
    @templateOptions.users = [{}].concat @options.users
