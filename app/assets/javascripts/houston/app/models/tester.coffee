class window.Tester extends Backbone.Model


class window.Testers extends Backbone.Collection
  model: Tester

  findByEmail: (email)->
    @find (tester)-> tester.get('email') == email
