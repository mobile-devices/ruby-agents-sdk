var App = (function(app) {
  // events management

  $(document).ready(function() {

    // app events
    app.suscribe('app.notify.agents_server_status', function(event, status) {
      switch(status) {
        case "online":
          $("#run-tests").removeClass("disabled");
          $("#save-tests-results").removeClass("disabled").attr("href","/tests/status/text");
          break;
        case "offline":
          $("#run-tests").addClass("disabled");
          $("#save-tests-results").addClass("disabled").removeAttr("href");
          break;
        default:
          console.warn("Unknown server status: " + status);
      }
    });

    app.suscribe('app.notify.agents_available', function(event, params) {
      var context = {agents: []};
      for(var i = 0, len = params.length; i < len; i++) {
        context.agents.push({name: params[i]});
      }
      var template = Handlebars.compile($('#available-agents-tmpl').html()); // todo compile only once
      $('#available-agents').html(template(context));
    });

    app.suscribe('app.notify.agents_selected', function(event, selectedAgents) {
      // test if all agents are selected. If there is only one available agent, display the agent name instead.
      if (selectedAgents.length != testUpdater.availableAgents.length || testUpdater.availableAgents.length == 1) {
        $("#select-agent-btn").html(selectedAgents.join(", ") + ' <span class="caret"></span>');
      } else {
        $("#select-agent-btn").html('All agents <span class="caret"></span>');
      }
      testConfig.selectedAgents = selectedAgents;
    });

    app.suscribe('app.action.start_tests', function(event, testConfig, testUpdater) {
      if (testConfig.selectedAgents.length > 0) {
        testLauncher.startTests(testConfig.selectedAgents);
      } else {
        console.warn("No agent selected");
      }
    });

    app.suscribe('app.action.stop_tests', function(event) {
      testLauncher.stopTests();
    });

    app.suscribe('app.notify.tests_started', function(event, agents) {
      testLauncher.testsRunning = true;
      $("#run-tests").removeClass('btn-primary').addClass('btn-danger').text("Stop tests");
      for(var i = 1, len = arguments.length; i < len ; i++) {
        delete testSuites[arguments[i]];
      }
      testUpdater.startUpdates();
    });

    app.suscribe('app.notify.tests_stopped', function(event) {
      testLauncher.testsRunning = false;
      $("#run-tests").removeClass('btn-danger').addClass('btn-primary').text("Run tests");
      // testUpdater.stopUpdates();
    });

    app.suscribe('app.notify.test_progress', function(event, agentName, statusInfo) {
      if(agentName == "no tests") {
        $('#general-test-info').html("<p class='alert alert-info'>No tests are currently running.</p><p><small>Select the agents to test in the above dropdown and click the Run tests button.</small></p>");
        return;
      }
      $('#general-test-info').html("");
      var testSuite;
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
      // check if the HTML for tdisplaying the test suite exists. If not, create it.
      var root = $('#test-suite-'+ testSuite.agentName);
      if(!root.length) {
        $('#test-suites-container').append("<div id='test-suite-" + testSuite.agentName + "'></div>");
        root = $('#test-suite-'+ testSuite.agentName);
      }

      // update the GUI according to the received status
      var template;
      switch(testSuite.status) {
        case "exception":
          template = Handlebars.compile($('#test-suite-exception-tmpl').html()); // todo compile only once
          break;
        case "no test directory":
          template = Handlebars.compile($('#no-test-directory-tmpl').html()); // todo compile only once
          break;
        case "aborted":
          template = Handlebars.compile($('#test-suite-aborted-tmpl').html()); // todo compile only once
          break;
        case "scheduled":
          template = Handlebars.compile($('#test-suite-scheduled-tmpl').html()); // todo compile only once
          break;
        case "not scheduled":
          template = Handlebars.compile($('#test-suite-not-scheduled-tmpl').html()); // todo compile only once
          break;
        case "finished":
          template = Handlebars.compile($('#test-suite-finished-tmpl').html()); // todo compile only once
          break;
        case "running":
          template = Handlebars.compile($('#test-suite-running-tmpl').html()); // todo compile only once
          break;
        default:
          console.warn("Presenter: unknown test suite status: " + testSuite.status);
          return;
      }
      Handlebars.registerPartial("result", $("#test-suite-result-partial").html());
      root.html(template(testSuite));
    });

    // user events
    $('#available-agents').on("click", "li a", function() {
      var agentsToTest = [];
      if($(this).text() == "All agents") {
        agentsToTest = testUpdater.availableAgents;
      } else {
        agentsToTest = [$(this).text()];
      }
      app.publish('app.notify.agents_selected', [agentsToTest]);
    });

    $('#run-tests').click(function() {
      if(!testLauncher.testsRunning) {
        app.publish('app.action.start_tests', [testConfig, testUpdater]);
      } else {
        app.publish('app.action.stop_tests');
      }
    });

    $('#test-suites-container').on("click", "table .failed-example a", function(e) {
      e.preventDefault();
      $(this).parents("#test-suites-container table tr").next("tr").children("td").fadeToggle(50);
      $(this).find("i").toggleClass("icon-chevron-down icon-chevron-up");
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
