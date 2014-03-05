var App = (function(app) {
  // events management

  $(document).ready(function() {

    // app events
    app.suscribe('app.notify.agents_available', function(event, params) {
      var context = {agents: []};
      for(var i = 0, len = params.length; i < len; i++) {
        context.agents.push({name: params[i]});
      }
      var template = Handlebars.compile($('#available-agents-tmpl').html()); // todo compile only once
      $('#available-agents').html(template(context));
    });

    app.suscribe('app.notify.agents_selected', function(event, selectedAgents) {
      if (selectedAgents.length != testUpdater.availableAgents.length) { // all agents are selected
        $("#select-agent-btn").html(selectedAgents.join(", ") + ' <span class="caret"></span>');
      } else {
        $("#select-agent-btn").html('All agents <span class="caret"></span>');
      }  
      testConfig.selectedAgents = selectedAgents;
    });

    app.suscribe('app.action.start_tests', function(event, testConfig, testUpdater) {
      if (testConfig.selectedAgents.length > 0) {;
        testLauncher.startTests(testConfig.selectedAgents);
      } else {
        console.warn("No agent selected");
      }
    });

    app.suscribe('app.action.stop_tests', function(event) {
      testLauncher.stopTests();
    });

    app.suscribe('app.notify.tests_started', function(event) {
      $("#run-tests").removeClass().addClass('btn btn-danger').text("Stop tests");
      testUpdater.startUpdates();
    });

    app.suscribe('app.notify.tests_stopped', function(event) {
      $("#run-tests").removeClass().addClass('btn btn-primary').text("Run tests");
      testUpdater.stopUpdates();
    });

    app.suscribe('app.notify.test_progress', function(event, agentName, statusInfo) {
      var testSuite;
      if(agentName == "no tests") {
        var template = Handlebars.compile($('#test-suite-exception-tmpl').html()); // todo compile only once
        return;
      }
      // retrieve the correct test suite
      if(testSuites.hasOwnProperty(agentName)) {
        testSuite = testSuites[agentName];
      } else {
        testSuite = new app.TestSuite(agentName);
        testSuites[agentName] = testSuite;
      }
      // and update it
      testSuite.processUpdate(statusInfo);
    });

    app.suscribe('app.notify.test_suite.changed', function(event, testSuite) {
      switch(testSuite.status) {
        case "exception":
          var template = Handlebars.compile($('#test-suite-exception-tmpl').html()); // todo compile only once
          // check if the THML for tdisplaying the test suite exists. If not, create it.
          var root = $('#test-suite-'+ testSuite.agentName)
          if(root.length) {
            root.html(template(testSuite));
          } else {
            $('#test-suites-container').append("<div id='test-suite-" + testSuite.agentName + "'></div>");
            root = $('#test-suite-'+ testSuite.agentName);
            root.html(template(testSuite));
          }
          break
        default:
          console.warn("Unknown test suite status: " + testSuite.status);
          break;
      }      
    });

    // user events
    $('#available-agents').on("click", "li a", function() {
      var agents_to_test = [];
      if($(this).text() == "All agents") {
        agents_to_test = testUpdater.availableAgents;
      } else {
        agents_to_test = [$(this).text()];
      }
      app.publish('app.notify.agents_selected', [agents_to_test]);
    });

    $('#run-tests').click(function() {
      if(!testLauncher.testsRunning) {
        app.publish('app.action.start_tests', [testConfig, testUpdater]);
      } else {
        app.publish('app.action.stop_tests');
      }
    });
    
    // variable initialization    
    var testConfig = new app.TestConfig();
    var testLauncher = new app.TestLauncher('/tests/start', 'tests/stop');
    var testUpdater = new app.TestUpdater('/tests/status');
    var testSuites = {}; //object holding all the test suites

    // init
    testUpdater.updateAvailableAgents('/tests/available_agents');
    testUpdater.startUpdates();

  }); // document ready

  return app;

})(App);