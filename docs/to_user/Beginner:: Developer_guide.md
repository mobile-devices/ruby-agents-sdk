
This documentation applies to sdk vm XXXX_VERSION.

The ruby_workspace folder is your workspace, you can't move it or rename it, but you can sym-link it if you want.

## Project management
To manage projects, go to http://localhost:5000/ with your favourite browser (you should use the ip of the VM's host instead of 'localhost' in order to access it through the network).

On this page, you can create/start/stop a project then apply and reboot the VM's ruby server to apply your modifications.

## Project structure
 When you have created your project in the SDK Agents tab you will see a folder with the same name in your workspace, it looks like :

* **initial.rb** : where your code adventure starts.
* **Gemfile** : where you put gems you need.
* **README.md** : where you explain what you do because documentation is mandatory.
* **config/** : folder where you put your configuration.
* **config/schedule.rb** : whenever file to create cron rules for scripts created in cron_tasks folder.
* **modules/** : folder where you create your ruby modules.

You will also find ib your workspace an sdk_logs with you find your agent's logs and also server's logs.

To test your code, just modify your code and 'apply and reboot' on the **http://localhost:5000/** web page.

The com interface runs on port 5001.

##### General guide-lines :

* You receive the messages in the initial.rb, you shall include your code in a sub .rb file in the lib folder.
* Do your agent stateless, global variables are strictly forbidden.
* To configure the dynamic channel used by this agent, go and edit config/<agent_name>.yml.example file.
* If you need additional gems, edit the Gemfile and require them here.
* Remember to complete your README.md


## Message handling

### Receive something from a device (@see initial.rb)

#### presence : This method is called when a connection/reconnection/deconnection happen.

``` ruby
def new_presence_from_device(meta, payload, account)
  ## Write your code here
  log_debug('initial:new_presence_from_device')
end
```

 With :

"**meta**", a map with some meta data, generally none.

"**payload**", a map with :

* asset   : imei of the device
* time    : timestamp of the event
* bs      : binary server source
* type    : 'connect' or 'reconnect' or 'disconnect'
* reason  : reason for the event

"**account**" (account name type String).

#### message : This method is called when a message is received from the device.

``` ruby
def new_message_from_device(meta, payload, account)
  msg = Message.new(payload)
  ## Write your code here
  log_debug('initial:new_message_from_device')
end
```

 With :

"**meta**", a map with some meta data, generally none.

"**payload**", a map with :

* id           : tmp id from the device
* asset        : imei of device
* sender       : Sender identifier (can be the same as the asset)
* recipient    : Recipient identifier (can be the same as the asset)
* type         : 'message'
* recorded_at  : timestamp
* received_at  : timestamp
* channel      : string channel
* payload      : content

"**account**" (account name type String).

note : class Message has the same structure as the payload.

#### track : This method is called when a tracking set of data is received from the device.

``` ruby
def new_track_from_device(meta, payload, account)
  ## Write your code here
  log_debug('initial:new_track_from_device')
end
```

"**meta**", a map with some meta data, generally none.

"**payload**", a map with :

* id           : tmp id from the device
* asset        : imei of device
* data map, with :
  * latitude
  * longitude
  * recorded_at
  * received_at
  * field1
  * field2
  * ...

"**account**" (account name type String).

#### order : This method is called when a schedule tasks is requested.

``` ruby
def remote_call(order, params)
  # Write your code here
  log_debug('initial:remote_call')
end
```

"**order**", the given order.

"**params**", a string or parameters.

### Send something to device

#### push message to device

    send_message_to_device(account, asset, content)

With :

"**account**" (account name type String).

"**asset**" (imei type integer).

"**content** (binary content, or string, or map)

#### reply a message to device

    reply_message_to_device(message, account, content)

"**message**" (message to reply to, type message).

"**account**" (account name type String).

"**content** (binary content, or string, or map)
