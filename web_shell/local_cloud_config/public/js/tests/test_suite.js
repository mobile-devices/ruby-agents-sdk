var App = (function(app) {

  app.TestSuite = function(name) {
    this.agentName = name;
    this.status = "not scheduled";
    this.examples = [];
  };

  // return the current number of examples that have been run
  app.TestSuite.prototype.testedCount = function() {
    return this.passedCount + this.failedCount + this.pendingCount;
  };

  app.TestSuite.prototype.processUpdate = function(info) {
    var newStatus = info.status;
    var oldStatus = this.status;
    var dirty = false;
    switch(newStatus) {
    case "exception":
      dirty = true;
      this.exceptionInfo = info.exception;
      break;
    case "aborted":
      dirty = true;
      this.updateCommonAttributes(info);
      break;
    case "no test directory":
      if(this.status != "no test directory") {
        dirty = true;
      }
      break;
    case "scheduled":
      dirty = true;
      break;
    case "finished":
      if(this.status != "finished") {
        dirty = true;
        this.updateCommonAttributes(info);
      }
      break;
    case "running":
      dirty = true;
      this.updateCommonAttributes(info);
      break;
    default:
      console.error("Unknown status update: " + newStatus);
      break;
    }
    if(dirty) {
      this.status = newStatus;
      app.publish("app.notify.test_suite.changed", [this]);
    }
  };

  app.TestSuite.prototype.updateCommonAttributes = function(info) {
    this.startTime = info.start_time;
    this.failedCount = info.failed_count;
    this.pendingCount = info.pending_count;
    this.passedCount = info.passed_count;
    this.exampleCount = info.example_count;
    if(info.hasOwnProperty("summary")) {
      this.duration = info.summary.duration;
    }
    if(info.hasOwnProperty("examples")) {
      for(var i = this.examples.length, len = info.examples.length; i < len; i++) {
        this.examples[i] = new app.TestCase(info.examples[i]);
      }
    }
  };

  return app;


})(App);
