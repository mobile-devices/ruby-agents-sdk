# @markup markdown
# @title Use the SDK API
# @author Xavier Demorpion

# SDK API: a guide #

The SDK provides two Ruby modules to help you write and debug the server code faster: SDK.API and SDK.CCS.

## Using the SDK APIs ##
The SDK generates a module named after your agent name which provides you the SDK utilities. If your agent name is "My Example Agent" then the name of this module is "Sdk\_api\_my\_example\_agent".

You just need to *include* this module in your classes:

``` ruby
class MyClass
  include Sdk_api_my_example_agent

  def say_hello
    logger = SDK.API.log
    logger.info("hello!")
  end

end
```

This module defines the `SDK` namespace which is already configured for your agent.

You don't need to include this module in your "Initial" module.

## SDK.API and SDK.CSS ##

SDK.API is a module that holds objects which are configured for your agent: a logger, a redis database, the configuration of your agent...

On the other hand, SDK.CCS (shortcut for CloudConnectServices) is a namespace of generic objects used by the SDK and does not hold any agent-specific configuration.

Read the full {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK SDK module documentation} for a complete reference of what is available.

## {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API SDK.API} quick reference ##

### Send messages to devices with `SDK.API.gate` ###

The key object for responding to your device messages is the `SDK.API.gate` object, an instance of the class {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::MessageGate MessageGate} already configured for your agent with the following methods:

- {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::MessageGate#reply gate.reply(msg, content)} will reply to a message with the given content
- {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::MessageGate#push gate.push(asset, account, content)} will push a message to the device identified by the given asset

**Examples**

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we push a protogenPOI object to the device.
  SDK.API.gate.push('13371337', 'sdk-vm-account', protogenPOI)
end
```

``` ruby
def new_msg_from_device(msg)
  # on each message received, we reply back with a protogenPOI object to the device.
  SDK.API.gate.reply(msg, protogenPOI)
end
```

``` ruby
def new_msg_from_device(msg)
  # on each message received, we reply back the same content (echo agent)
  SDK.API.gate.reply(msg, msg.content)
end
```

### Write logs with {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.log SDK.API.log} ###

{Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.log SDK.API.log} gives you access to a logger. Using this logger will gives you nicely formatted logs in the [Logs](http://0.0.0.0:5000/logSdkAgentsPunk#endlog) tab of the GUI. The lines you write with this logger will be put in bold.

The actual log file is stored in `ruby_workspace/sdk_logs/ruby-agents-sdk.log`.

There are five log levels available:

- `log.debug` is meant to display very detailed information about the inner workings of your agent.
- `log.info` is a higher level of logging used to print information about what your agent is doing.
- `log.warn` is used to log warnings about something that shouldn't have happened.
- `log.error` is used to log errors that your agent can handle.
- `log.fatal` is used to log errors that your agent can not handle.

**Example**

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we write 'hello presence' in logs as debug
  SDK.API.log.debug('hello presence')
end
```

### Other useful SDK.API tools ###

- {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.config SDK.API.config} allows you to access to your configuration defined in the file `config/<your_agent_name>.yml.example`.

- {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.redis SDK.API.redis} gives you access to a Redis database. Redis is a database living in RAM that you can use to cache data for faster access. More information [on the official Redis website](http://redis.io/).

- {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.root_path SDK.API.root_path} gives you the path of your agent root directory. You can use this folder to write files for instance. **Example:**

``` ruby
def new_presence_from_device(presence)
  # on each presence received, I want to read my 'list.txt' file in my folder lib
  lines =  File.read("#{SDK.API::root_path}/lib/list.txt")
end
```

## {CloudConnectServices SDK.CCS} quick reference ##

This modules defines the events that are received by you agent:

- {CloudConnectServices::Message}
- {CloudConnectServices::Track}
- {CloudConnectServices::Presence}
- {CloudConnectServices::Order}
