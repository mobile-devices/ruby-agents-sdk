Here a sum-up of what features you can handle from the server/ruby side, you call them directly from your ruby code :

## config

#### description :

Give you access of your configuration set in the file config/<you_agent_name>.yml.example as a ruby hash.
Write in the config hash object wont write into the config file.

#### methods :

Ruby method Hash object :  @see documentation [on ruby Hash official documentation](http://www.ruby-doc.org/core-1.9.3/Hash.html).

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we read the config value of param 'dynamic_channel_str'
  puts "dynamic_channel_str value = #{config['dynamic_channel_str']}"

end
```


## gate

#### description :

Send/reply messages with protogen content to a device.

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
  # on each presence received, we push a protogenPOI objet to the device.
  gate.push('13371337', 'sdk-vm-account', protogenPOI)
end
```

``` ruby
def new_msg_from_device(msg)
  # on each message received, we reply back with a protogenPOI objet to the device.
  gate.reply(msg, protogenPOI)
end
```

``` ruby
def new_msg_from_device(msg)
  # on each message received, we reply back the same content (echo agent)
  gate.reply(msg, msg.content)
end
```


## log

#### description :

Use it to write some log while runtime.

#### methods :

* log.debug(text)
* log.info(text)
* log.warn(text)
* log.error(text)

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we write 'hello presence' in logs as debug
  log.debug('hello presence')
end
```

## redis

#### description :

Use it to cache data for faster reply.

#### methods :

This object has all redis api as documented below (using redis 3.0.4), @see documentation [on official redis webwite](http://redis.io/).

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, we set the redis key 'pom' to 'pyro' value
  redis['pom'] ='pyro'
  # we also ping the server for the fun
  redis.ping
end
```

## redis_shared

#### description :

Use it to cache data for faster reply (@see redis), but the keys will be shared between several instances of your agent dispatched into the cloud.

#### methods :

@see redis

#### example :

@see redis



## root_path

#### description :

Give you the path of your agent root directory.

#### methods :

Ruby method String object :  @see documentation [on ruby String official documentation](http://www.ruby-doc.org/core-1.9.3/String.html).

#### example :

``` ruby
def new_presence_from_device(presence)
  # on each presence received, I want to read my 'list.txt' file in my folder lib
  lines =  File.read("#{root_path}/lib/list.txt")
end
```

