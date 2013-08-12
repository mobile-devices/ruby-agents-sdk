
This documentation applies to sdk vm XXXX_VERSION.

The **ruby_workspace** folder is your workspace, you can't move it or rename it, but you can sym-link it if you want.

## Agents management
Gui interface : http://localhost:5000/

On this page, you can create/start/stop a project then reboot the VM's ruby server to apply your modifications.

## Agent structure
 When you have created your project in the SDK Agents tab, you will see a folder with the same name in your workspace, it looks like:

* **initial.rb** : where your code adventure starts.
* **Gemfile** : where you put the gems you need.
* **README.md** : where you explain what you do because documentation is mandatory.
* **config/** : folder where you put your configuration.
* **config/protogen.json** : configuration of messages that can be exchanged between device and server.
* **config/schedule.rb** : a *whenever* file to create your scheduled cron rules folder.
* **doc/** : folder where you put your documentation.
* **doc/protogen/** : folder where the protocol's documentation is generated.
* **modules/** : folder where you create your ruby modules.

You will also find in your workspace an *sdk\_logs* folder where you will find your agent's logs (file *ruby-agent-sdk-server.log*) and also server's logs.

To test your code, just modify your code and 'apply and reboot' on the **http://localhost:5000/** web page.

The com interface runs on port 5001.

##### General guide-lines :

* You receive the messages in the initial.rb, you shall include your code in a sub .rb file in the lib folder.
* Do your agent stateless, global variables are strictly forbidden.
* If you use messages, follow the Protogen Guide to see how to configure your messages.
* To configure the dynamic channel used by this agent, go and edit the *config/\<agent\_name\>.yml.example* file, you can put a string or an array of string (see YAML documention for syntax).
* You also need to configure **which kind of message you want to receive** in your agent with parameters 'subscribe\_presence', 'subscribe\_message' and 'subscribe\_track'.
* If you need additional gems, edit the Gemfile and require them here.
* Remember to complete your README.md


## Message handling

### Receive something from a device (@see initial.rb)

#### presence : This method is called when a connection/reconnection/deconnection happen.

``` ruby
def new_presence_from_device(presence)
  ## Write your code here
  log.debug('initial:new_presence_from_device')
end
```

Where *presence* is a class with the following accessors :

* **asset**   : imei of the device
* **time**    : timestamp of the event
* **bs**      : binary server source
* **type**    : 'connect' or 'reconnect' or 'disconnect'
* **reason**  : reason for the event
* **account** : account name type String
* **meta**    : a map with some meta data, generally none.


#### message : This method is called when a message is received from the device.

``` ruby
def new_msg_from_device(message)
  ## Write your code here
  log.debug('initial:new_message_from_device')
end
```

Where *message* is a class with the following accessors :

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


#### track : This method is called when a tracking set of data is received from the device.

``` ruby
def new_track_from_device(track)
  ## Write your code here
  log.debug('initial:new_track_from_device')
end
```

Where *track* is a class with following accessors :

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

#### order : This method is called when a schedule tasks is requested.

``` ruby
def new_order(order)
  # Write your code here
  log.debug('initial:new_order')
end
```
Where *order* is a class with following accessors :

* **agent**        : agent name concerned by the order
* **code**         : code specified into the schedule.rb (@see Schedule tasks with cron documentation)
* **params**       : a string or parameters (@see Schedule tasks with cron documentation)


### Send something to device

Use the gate API (see the API server documentation).
