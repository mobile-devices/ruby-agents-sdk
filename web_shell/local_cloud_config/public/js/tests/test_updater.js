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
      this.isPolling = true; // we must be ure that isPolling is set to true before sending the updateRequest
      console.log("TestUpdater: start polling the server for updates");
      this.sendUpdateRequest();
    } else {
      console.log("TestUpdater: (info) already polling the server, ignoring startUpdates command.");
    }
    this.isPolling = true;
  }

  // Stop polling the server for test status updates
  app.TestUpdater.prototype.stopUpdates = function() {
    this.isPolling = false;
    console.log("TestUpdater: stop polling the server for updates.");
  }

  // "private" methods
  app.TestUpdater.prototype.sendUpdateRequest = function() {
    if(this.isPolling) { // do not send the request if we cancelled the polling
       console.log("TestUpdater: sending update request.");
      $.ajax({
        url: this.pollingUrl, // todo add filter here
        type: "GET",
        context: this,
        success: this.processStatusUpdate,
        error: this.publishError
      })
    } else {
      console.log("TestUpdater: (info) not sending update request because polling is off.");
    }
  } 

  app.TestUpdater.prototype.publishError = function(data, code, xhr) {
    console.warn("TestUpdater: error when trying to update test status: " + data + " " + code);
    app.publish('app.notify.error.update_test_status', [data, code, xhr]);
    setTimeout($.proxy(this.sendUpdateRequest, this), this.pollingInterval);
  }
  
  app.TestUpdater.prototype.processStatusUpdate = function(data, code, xhr) {
    //console.log(data)
    app.publish('app.notify.agent_server_status', ["online"]);
    var parsedData = $.parseJSON(data);
    if(parsedData.status == "no tests") {
      app.publish('app.notify.test_progress', ["no tests"]);
      app.publish('app.notify.tests_stopped');
    } else {
      var testsStopped = true;
      for(var agentName in parsedData) {
        app.publish('app.notify.test_progress', [agentName, parsedData[agentName]]);
        if (parsedData[agentName]["status"] == "running" || parsedData[agentName]["status"] == "scheduled") {
          testsStopped = false;
        }
      } 
      if(testsStopped) {
        app.publish('app.notify.tests_stopped');
        this.stopUpdates();
      }
    }
    if(this.isPolling) {
      setTimeout($.proxy(this.sendUpdateRequest, this), this.pollingInterval);
    } else {
       console.log("TestUpdater: (info) after status update, not planning a new request because polling is off");
    }    
  }

  return app;

})(App);