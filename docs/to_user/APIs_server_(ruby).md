The SDK provides two Ruby modules to help you write and debug the server code faster: SDK.API and SDK.CCS.

## Using the SDK APIs
The SDK generates a module named after your agent name which provides you the SDK utilities. If your agent name is "My Example Agent" then the name of this module is "Sdk\_api\_my\_example\_agent".

You just need to *include* this module in your classes:

``` ruby
class MyClass
  include Sdk_api_my_example_agent

  def say_hello
    logger = SDK.API::log
    logger.info("hello!")
  end

end
```

## SDK.API documentation

This namespace provides objects that are already configured with your agent specific requirements.

### SDK.API::config

#### description :

A Ruby hash that gives you access to your configuration defined in the file *config/\<your\_agent\_name\>.yml.example*.
Writing in the config hash object will not write in the config file.

#### methods :

Ruby methods of the Hash class: see [the official Ruby documentation on Hash](http://www.ruby-doc.org/core-1.9.3/Hash.html).

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we read the config value of param 'dynamic_channel_str'
  puts "dynamic_channel_str value = #{config['dynamic_channel_str']}"

end
```

### SDK.API::gate

#### description :

Send/reply to messages to a device.

#### methods :

* push(asset, account, content)
  * asset : imei of the device.
  * account : account name to use.
  * content : protogen object to send.
* reply(msg, content)
  * msg : message to reply to.
  * content : protogen object to reply with.

#### examples :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we push a protogenPOI object to the device.
  SDK.API::gate.push('13371337', 'sdk-vm-account', protogenPOI)
end
```

``` ruby
def new_msg_from_device(msg)
  # on each message received, we reply back with a protogenPOI object to the device.
  SDK.API::gate.reply(msg, protogenPOI)
end
```

``` ruby
def new_msg_from_device(msg)
  # on each message received, we reply back the same content (echo agent)
  SDK.API::gate.reply(msg, msg.content)
end
```


### SDK.API::log

#### description :

Use it to write some logs during runtime. Your logs are written in the *sdk\_logs/ruby-agent-sdk-server.log* file and you can see them in the "Server Log" tab of the GUI interface.

#### methods :

* log.debug(text)
* log.info(text)
* log.warn(text)
* log.error(text)

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we write 'hello presence' in logs as debug
  SDK.API::log.debug('hello presence')
end
```

### <a id="redis"></a> SDK.API::redis

#### description :

Use Redis to cache data for faster reply.

#### methods :

This object matches the redis API (using redis 3.0.4), see documentation [on official redis webwite](http://redis.io/). The complete list of available commands is available [on redis-rb documentation](http://rdoc.info/github/redis/redis-rb/Redis).

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we set the redis key 'pom' to 'pyro' value
  SDK.API::redis['pom'] ='pyro'
  # we also ping the server for the fun
  SDK.API::redis.ping
end
```

### SDK.API::redis\_shared

#### description :

Use it to cache data for faster reply (see [redis](#redis)), but the keys will be shared between several instances of your agent dispatched into the cloud.

#### methods :

see [redis](#redis)

#### example :

see [redis](#redis)



### SDK.API::root_path

#### description :

Gives you the path of your agent root directory. You can use this folder to write files for instance.

#### methods :

Ruby methods of the String class: see [the official Ruby documentation on String](http://www.ruby-doc.org/core-1.9.3/String.html).

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, I want to read my 'list.txt' file in my folder lib
  lines =  File.read("#{SDK.API::root_path}/lib/list.txt")
end
```


## SDK.CCS documentation

The CloudConnect Services namespace defines classes and helper methods that are not specific to your agent.

### SDK.CCS::print\_ruby\_exception

Write to the logs a nicely formatted Ruby exception, complete with the error message and the stack trace.
*A note on the stack trace:* as your code is called from the SDK, the stack trace will include lines that do not come from your code. However, you will be able to spot in the stack trace the lines in your code that caused the exception.
Also note that exceptions that you do not catch yourself will be catched and displayed with this method before your code is terminated.

#### example:

``` ruby
def illegal_operation(arg)
  42/arg
end

def boom
  begin
    illegal_operation(0)
  rescue ZeroDivisionError => e
    SDK.CCS::print_ruby_exception(e)
  end
end
```

### SDK.CCS::Presence

A class that represents the data received by the server when a device is connected/disconnected.

#### Accessors

* **asset**   : imei of the device
* **time**    : timestamp of the event
* **bs**      : binary server source
* **type**    : 'connect' or 'reconnect' or 'disconnect'
* **reason**  : reason for the event
* **account** : account name type String
* **meta**    : a map with some meta data, generally none.

### SDK.CCS::Message

A class that represents a message sent by a device and received by the server.

#### Accessors

* **id**           : tmp id from the device
* **parent_id**    : tmp id from the device
* **thread_id**    : tmp id from the device
* **asset**        : imei of device
* **sender**       : Sender identifier (can be the same as the asset)
* **recipient**    : Recipient identifier (can be the same as the asset)
* **type**         : 'message'
* **recorded_at**  : timestamp
* **received_at**  : timestamp
* **channel**      : string channel
* **account**      : account name type String
* **content**      : content, generaly an instance of a class provided by protogen
* **meta**         : a map with some meta data, generally none

### SDK.CCS::Track

A class that represents the data received by the server when a device is connected/disconnected.

#### Accessors

* **id**           : tmp id from the device
* **asset**        : imei of device
* **account**      : account name type String
* **meta**         : a map with some meta data, generally none
* **data**         : a map, with :
  * latitude
  * longitude
  * recorded_at
  * received_at
  * field1
  * field2
  * ...

### SDK.CCS::Order

A class that represents a scheduled order.

#### Accessors

* **agent**        : agent name concerned by the order
* **code**         : code specified into the schedule.rb (@see Schedule tasks with cron documentation)
* **params**       : a string or parameters (@see Schedule tasks with cron documentation)