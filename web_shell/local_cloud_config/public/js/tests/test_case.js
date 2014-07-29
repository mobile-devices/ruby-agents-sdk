var App = (function(app) {

  // A test case is an "example" in RSpec terminology.
  // Definition must be an object with the following fields :
  // * description -> name of the example
  // * full_description
  // * status -> either "passed", "failed", "pending"
  // * line_number
  // * duration (if example has finished running)
  // * example_index
  // * exception : an object with fields class, message and backtrace
  // * file_path
  app.TestCase = function(definition) {
    this.description = definition.description;
    this.fullDescription = definition.full_description;
    this.status = definition.status;
    this.lineNumber = definition.line_number;
    this.duration = definition.duration;
    this.index = definition.example_index;
    this.exception = definition.exception;
    this.filePath = definition.file_path;
    this.isBacktraceExpanded = false;
    this.useFullBacktrace = false;
    this.cleanedBacktrace = this.buildCleanedBacktrace();
  };

  app.TestCase.prototype.hasPassed = function() {
    return this.status == "passed";
  };

  app.TestCase.prototype.hasFailed = function() {
    return this.status == "failed";
  };

  app.TestCase.prototype.buildCleanedBacktrace = function() {
    if(this.exception !== null && this.exception !== undefined) {
      this.cleanedBacktrace = [];
      var backtrace = this.exception.backtrace;
      var backtraceLen = backtrace.length;
      for(var i = 0; i < backtraceLen; i++) {
        if(backtrace[i].match(/\/home\/vagrant\/ruby-agents-sdk\/web_shell\/local_cloud\/ragent_bay\/agents_project_source\//)) {
          backtrace[i] = new String(backtrace[i]); // quick and dirty way to add a property to a string
          backtrace[i].important = true;
          this.cleanedBacktrace.push(backtrace[i].slice(85));
        }
      }
    }
    return this.cleanedBacktrace;
  };

  app.TestCase.prototype.cleanBacktrace = function() {
    if(!this.useFullBacktrace) {
      return this.cleanedBacktrace;
    } else {
      return this.exception.backtrace;
    }
  };

  return app;

})(App);
