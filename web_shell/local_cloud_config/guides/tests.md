# @markup markdown
# @title Test your agent
# @author Xavier Demorpion

# Test your agent #

The SDK integrates with [RSpec](http://rspec.info/) version 2.14 to automate your tests. RSpec documentation can be found [here](http://rubydoc.info/gems/rspec/file/README.md).

The SDK GUI has a [tab](http://0.0.0.0:5000/unit_tests) dedicated to running and displaying RSpec tests.

Additionnally, the SDK API exposes a couple of helpers utilities. You can find these utilities in the module `TestHelper` ; this module is automatically available in your tests files. Read the {TestsHelper TestsHelper module documentation} to see what helpers are available.

## Writing tests with Rspec ##

The tests for your agent must be placed in a `tests` subfolder in your agent root directory. A test file must have a name ending with `_spec.rb`. Other files will not be read by RSpec (but you can still require them on your tests, for instance if you need specific helpers).

As an example, let's assume we have a "tester" agent with the following `initial.rb`:

``` ruby
module Initial_agent_tester

  # Store all connection events in a redis database
  # Note: this is a terrible idea for a real agent :-)
  def new_presence_from_device(presence)
    if presence.type == "connect"
      user_api.mdi.storage.redis[presence.asset] =  presence.time
    elsif presence.type == "disconnect"
      user_api.mdi.storage.redis[presence.asset] = nil
    end
  end

  # Echo all received messages twice.
  def new_msg_from_device(msg)
    3.times { user_api.mdi.device_gate.reply(msg, msg.content) # Bug here, let's see if the tests will reveal it...
  end

end
```

This agent suscribes to messages and presences on the channel "com.mdi.services.tester" in his config file.

To make sure this agent has the desired behaviour, we're going to write tests for it.

Create a subfolder named `tests` in `ruby_workspace/tester/`. In this subfolder place a file named `basic_spec.rb` with the following content:

``` ruby
# no require directive needed

describe 'tester agent' do

  it 'stores all connection events in a redis database' do
    presence = TestsHelper::DevicePresence.new("connect", "1234")
    presence.send_to_server # blocking call
    expect(user_api.mdi.redis.get(presence.asset)).to eq(presence.time.to_s)
  end

  it 'echoes all received messages twice' do
    msg = TestsHelper::DeviceMessage.new(content, "com.mdi.services.tester", "1234", "tester_account")
    msg.send_to_server
    responses = TestsHelper::wait_for_responses(msg, nil, 1) # retrieve all responses in the following second
    expect(responses).to have(2).items
    expect(responses.first.content).to eq(content)
  end

end
```

Read the [RSpec documentation](http://rubydoc.info/gems/rspec/file/README.md) for more information on how you can write tests with RSpec and the {TestsHelper TestsHelper module documentation} to see what tools the SDK gives you to write tests.

## Running your tests ##

Go to the ["Unit tests"](http://0.0.0.0:5000/unit_tests) tab of the SDK GUI. This tab displays the status of the last tests which were executed for all mounted agents.

Make sure your agent is mounted (tab ["SDK agents"](http://0.0.0.0:5000)), restart the agents server (top-right button), select your agent in the dropdown menu and click the blue "run tests" button.

In our example, there is one failing test and one passing test. You can display additional information about the failing test by clicking on the red label.

## Saving tests results ##

It is a good idea to regularly save your tests results to know which tests passed or failed at a given point in time. You can download the tests result in raw text by clicking the dedicated button on the test page.

## Protogen in your tests

You can test the Protogen callbacks by calling them directly in your tests with a hand-crafted mock message object (see {UserApis::Mdi::Dialog::MessageClass}) whose content is a Protogen object.

## Caveat ##

* The version of your agent which is effectively tested is the one currently mounted i.e. the last version you had before restarting the agents server. To test the latest version of your code, restart the agents server. Note that this comment also applies to your testing code (so modifying your testing code will not have any effect on your tests until you reboot the agents server).

* The test environement is not isolated, so for instance the log tab will display simulated messages exchanged between the simulated devices and the server. It also means that you could potentially have interferences between your tests and tasks you are executing while your tests are running. We highly recommand you don't do anything with the VM while you are running tests, and that you restart the agents server just before running your tests.

* Use the RSpec mock capabilities if your agent relies on external APIs but you don't want them to interfere in your tests. Still, it is a good idea to have tests that mock as little as possible so they represent better the real environment of your agent.

* Passing tests don't guarantee that your code works. 