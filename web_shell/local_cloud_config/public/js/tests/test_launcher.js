var App = (function(app) {

	app.TestLauncher = function(startUrl, stopUrl) {
		this.startUrl = startUrl;
		this.stopUrl = stopUrl;
		this.testsRunning = false;
	};

	// start tests for the given agents, does nothing if tests are already started
	// # POST /tests/start
	// # Content-Type: application/json
	// # {
	// # "agents": ["name_a", "name_b"]...
	// # }
	app.TestLauncher.prototype.startTests = function(agents) {
		if(!this.requestPending) { // do not start tests twice
			if(!this.testsRunning) {
				this.requestPending = true;
				$.ajax({
					url: this.startUrl,
					data: JSON.stringify({"agents": agents}),
					contentType: "application/json",
					dataType: "json",
					type: "POST",
					context: this,
					success: function() {
						app.publish('app.notify.agents_server_status', ["online"]);
						app.publish("app.notify.tests_started", agents);
						this.testsRunning = true;
					},
					complete: function() {
						this.requestPending = false;
					}
				});
			} else {
				console.warn("Tests are already started, impossible to start them again.");
			}
		} else {
			console.debug("Request pending...");
		}
	};

	// stop tests
	app.TestLauncher.prototype.stopTests = function() {
		if(!this.requestPending) {
			if(this.testsRunning) {
				this.requestPending = true;
				$.ajax({
					url: this.stopUrl,
					context: this,
					data: "",
					type: "POST",
					success: function() {
						app.publish('app.notify.agents_server_status', ["online"]);
						this.testsRunning = false;
						app.publish("app.notify.tests_stopped");
					},
					complete: function() {
						this.requestPending = false;
					}
				});
			} else {
				console.warn("Test are not started, impossible to stop them.");
			}
		} else {
			console.debug("Request pending...");
		}
	};

	return app;

})(App);
