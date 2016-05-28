class @Task extends Backbone.Model
  urlRoot: '/tasks'

class @Tasks extends Backbone.Collection
  model: Task
