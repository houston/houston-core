class window.User extends Backbone.Model
  
  canEditTickets: -> @get('admin')
