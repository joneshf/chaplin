'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'

module.exports = class Controller

  # Borrow the static extend method from Backbone
  @extend = Backbone.Model.extend

  # Mixin Backbone events and EventBroker.
  _(@prototype).extend Backbone.Events
  _(@prototype).extend EventBroker

  view: null

  # Internal flag which stores whether `redirectTo`
  # was called in the current action
  redirected: false

  # You should set a `title` property on the derived controller. Like this:
  # title: 'foo'

  constructor: ->
    @initialize arguments...

  initialize: ->
    # Empty per default

  adjustTitle: (subtitle) ->
    @publishEvent '!adjustTitle', subtitle

  # Composer
  # --------

  # Convenience method to publish the `!composer:compose` event. See the
  # composer for information on parameters, etc.
  compose: (params...) ->
    @publishEvent '!composer:compose', params...

  # Redirection
  # -----------

  # Redirect to URL.
  redirectTo: (url, options = {}) ->
    @redirected = true
    @publishEvent '!router:route', url, options, (routed) ->
      unless routed
        throw new Error 'Controller#redirectTo: no route matched'

  # Redirect to named route.
  redirectToRoute: (name, params, options) ->
    @redirected = true
    @publishEvent '!router:routeByName', name, params, options, (routed) ->
      unless routed
        throw new Error 'Controller#redirectToRoute: no route matched'

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Dispose and delete all members which are disposable
    for own prop of this
      obj = this[prop]
      if obj and typeof obj.dispose is 'function'
        obj.dispose()
        delete this[prop]

    # Unbind handlers of global events
    @unsubscribeAllEvents()

    # Remove properties which are not disposable
    properties = ['redirected']
    delete this[prop] for prop in properties

    # Finished
    @disposed = true

    # You're frozen when your heart’s not open
    Object.freeze? this
