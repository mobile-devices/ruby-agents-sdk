var App = (function(app) {

  // /test/status
  app.TestUpdater = function(pollingUrl) {

    this.pollingInterval = 2000;
    this.pollingUrl = pollingUrl;
    this.isPolling = false;
    this.availableAgents = [];

  }

  // fetch which agents are available to test and publish an event once its done
  app.TestUpdater.prototype.updateAvailableAgents = function() {
     $.ajax({
        url: '/tests/available_agents',
        type: "GET",
        context: this,
        success: function(data, code, xhr) { // proxy useful so this refers to te TestUpdater in the event handler
          this.availableAgents = JSON.parse(data);
          app.publish('app.notify.agents_available', [this.availableAgents]);
        }
      });
   }

  // Poll the server on a regular basis to retrieve test status
  app.TestUpdater.prototype.startUpdates = function() {
    if(!this.isPolling) {
      this.isPolling = true;
      this.sendUpdateRequest();
    }
  }

  // Stop polling the server for test status updates
  app.TestUpdater.prototype.stopUpdates = function() {
    this.isPolling = false;
  }

  // "private" methods
  app.TestUpdater.prototype.sendUpdateRequest = function() {
    if(this.isPolling) { // do not send the request if we cancelled the polling
      $.ajax({
        url: this.pollingUrl, // todo add filter here
        type: "GET",
        context: this,
        success: this.processStatusUpdate,
        error: this.publishError
      })
    }
  } 

  app.TestUpdater.prototype.publishError = function() {
    console.log("error"); // todo
  }
  
  app.TestUpdater.prototype.processStatusUpdate = function(data, code, xhr) {
    console.log(data) // todo here -> update the models, publish a "update complete" event.
    var parsedData = $.parseJSON(data);
    if(parsedData.status == "no tests") {
      app.publish('app.notify.test_progress', ["no tests"]);
    }
    for(var agentName in parsedData) {
      app.publish('app.notify.test_progress', [agentName, parsedData[agentName]]);
    }
    if(this.isPolling) {
      setTimeout($.proxy(this.sendUpdateRequest, this), this.pollingInterval);
    }
  }

  return app;

})(App);