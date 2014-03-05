var App = (function() {

  var app = {},
      o = $(document);

  // public methods

  // publisher-suscriber simple implementation

  // Suscribe to a topic.
  // Exemple: app.suscribe('topic.example.notif', function(_, param1, param2) {
  // ...
  // })
  app.suscribe = function() {
    o.on.apply(o, arguments);
  }

  // Remove all listeners to an event. Use with care !
  app.unsuscribe = function() {
    o.off.apply(o, arguments);
  }

  // Publish an event. 
  // example : app.publish('topic.example', [param1,param2])
  app.publish = function(name, parameters) {
    if(undefined === parameters) {
      console.debug("Published event: " + name + " without any parameter");
    } else {
      console.debug("Published event: " + name + " with parameters " + parameters.toString());
    }
    o.trigger.apply(o, arguments);
  }

  return app;
})();