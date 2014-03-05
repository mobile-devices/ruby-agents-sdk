var App = (function(app) {

  app.TestSuite = function(name) {
    this.agentName = name;
    this.status = "not scheduled";
  }

  // return the current number of examples that have been run
  app.TestSuite.prototype.testedCount = function() {
    return this.passedCount + this.failedCount + this.pendingCount;
  }

  app.TestSuite.prototype.processUpdate = function(info) {
    var newStatus = info["status"];
    var dirty = false;
    if(newStatus == "exception") {
      dirty = true;
      this.status = "exception";
      this.exceptionInfo = info["exception"];
    } else {
      console.error("Unknown status update: " + newStatus);
    }
    if(dirty) {
      app.publish("app.notify.test_suite.changed", [this]);
    }
  }

  return app;


})(App);