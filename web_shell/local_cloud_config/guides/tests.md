# @markup markdown
# @title Test your agent
# @author Xavier Demorpion

# Test your agent #

The SDK makes testing your agent easy. You can test your code without having a device, and thus verifying that your agent works without having to use (and debug the code of) your device.

We advise you to use [Rspec](http://rspec.info/) to automate your tests. Rspec documentation can be found [here](http://rubydoc.info/gems/rspec/file/README.md).

The SDK GUI has a [tab](http://0.0.0.0:5000/unit_tests) dedicated to running and displaying Rspec tests. Rspec is already integrated in the SDK VM.

Additionnally, the SDK API exposes a couple of utilities that you can use to simulate communication with a device. You can find these utilities in the module `TestHelper` (you need to `require 'tests_helper'` first). Read the {TestsHelper TestsHelper module documentation} to see what helpers are available.

## Writing tests with Rspec ##

The tests for your agent must be placed in a `tests` subfolder in your agent root directory. A test file must have a name ending with `_spec.rb`.

As an example, let's assume we have a "tester" agent with the following `initial.rb`:

``` ruby
module Initial_agent_tester

  include Sdk_api_tester

  # Store all connection events in a redis database
  def new_presence_from_device(presence)
    if presence.type == "connect"
      SDK.API.redis[presence.asset] =  presence.time
    elsif presence.type == "disconnect"
      SDK.API.redis[presence.asset] = nil
    end
  end

  # Echo all received messages twice.
  def new_msg_from_device(msg)
    3.times { SDK.API.gate.reply(msg, msg.content) # Error here, let's see if the tests will reveal it...
  end

end
```

This agent suscribes to messages and presences on the channel "com.mdi.services.tester" in his config file.

To make sure this agent has the desired behaviour, we're going to write tests for it.

We create a subfolder named `tests` in `ruby_workspace/tester/`. In this subfolder we place a file named `basic_spec.rb` with the following content:

``` ruby
require 'rspec'
require 'tests_helper' # to access the TestsHelper module

describe 'tester agent' do

  it 'should store all connection events in a redis database' do
    presence = TestsHelper::PresenceFromDevice.new("connect", "1234")
    presence.send_to_server
    TestsHelper.wait_for { SDK_api_tester::SDK.API.redis.get(presence.asset).should == presence.time.to_s}
  end

  it 'should echo all received messages twice' do
    msg = TestsHelper::MessageFromDevice.new(content, "com.mdi.services.tester", "1234", "tester_account")
    msg.send_to_server
    responses = TestsHelper::wait_for_responses(msg,nil, 5) # retrieve all responses in the following 5 seconds
    responses.should have(2).items
    responses.first.content.should == content
    responses[1].content.should == content
  end

end
```

Read the [Rspec documentation](http://rubydoc.info/gems/rspec/file/README.md) for more information on how you can write tests with Rspec and the {TestsHelper TestsHelper module documentation} to see what tools the SDK gives you to write tests.

## Running your tests ##

Go to the ["Unit tests"](http://0.0.0.0:5000/unit_tests) tab of the SDK GUI. This tab displays the status of the last tests which were executed for all mounted agents.

Make sure your agent is mounted (tab ["SDK agents"](http://0.0.0.0:5000)), restart the agents server (top-right button), select your agent in the dropdown menu and click the blue "run tests" button.

In our example, we have one failing test and one passing test. We can display additional information about the failing tests by clicking on the red label.

## Saving tests results ##

It is a good idea to regularly save your tests results to know which tests passed or failed at a given point in time.

To do this, just click on the "save results" button. It will create a human-readable HTML file in `ruby_workspace/sdk_logs/tests_results/<your_agent_name>/` with the results of your tests. The file name includes the date at which you run your tests.

If your source code in under revision control by [Git](http://git-scm.com/), information about the latest commit will be included in this file as well.

## Use `shared_context` to tidy your tests ##

If you're using the `SDK` namespace a lot in your tests, it may be a good idea to put it in a [RSpec shared context](https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-context). Let's rewrite the first test:

``` ruby
require 'rspec'
require 'tests_helper'

shared_context 'tester_agent_context' do
  SDK = Sdk_api_sdk_tester::SDK
end

describe 'tester agent' do

  include_context 'tester_agent_context'

  it 'should store all connection events in a redis database' do
    presence = TestsHelper::PresenceFromDevice.new("connect", "1234")
    presence.send_to_server
    TestsHelper.wait_for {SDK.API.redis.get(presence.asset).should == presence.time.to_s}
  end

end
```

## Caveat ##

* The version of your agent which is effectively tested is the one currently mounted i.e. the last version you had before restarting the agents server. To test the latest version of your code, restart the agents server. Note that this comment also applies to your testing code (so modifying your testing code will not have any effect on your tests until you reboot the agents server).

* The test environement is not isolated, so for instance the log tab will display simulated messages exchanged between the simulated devices and the server. It also means that you could potentially have interferences between your tests and tasks you are executing while your tests are running. We highly recommand you don't do anything with the VM while you are running tests.

* Use the Rspec mock capabilities if your agent relies on external APIs but you don't want them to interfere in your tests. Still, it is a good idea to have tests that mock as little as possible so they represent better the real environment of your agent.

* Passing tests don't guarantee that your code works.