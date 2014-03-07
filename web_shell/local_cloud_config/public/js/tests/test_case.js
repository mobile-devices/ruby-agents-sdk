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
  }

  app.TestCase.prototype.hasPassed = function() {
    return this.status == "passed";
  }

  app.TestCase.prototype.hasFailed = function() {
    return this.status == "failed"
  }

  return app;

})(App);