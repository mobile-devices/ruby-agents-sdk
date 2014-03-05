var App = (function(app) {

  // A test case is an "example" in RSpec terminology.
  // Definition must be an object with the following fields :
  // * description -> name of the example
  // * full_description
  // * status -> either "aborted", "scheduled", "started", "finished"
  // * line_number
  // * duration (if example has finished running)
  // * example_index
  // * exception : an object with fields class, message and backtrace
  app.TestCase = function(definition) {
    this.description = definition.description;
    this.fullDescription = definition.description;
    this.status = definition.status;
    this.lineNumber = definition.line_number;
    this.duration = definition.duration;
    this.exampleIndex = definition.example_index;
    this.exception = definition.exception;
  }

  return app;

})(App);