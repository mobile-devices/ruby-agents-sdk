
This documentation applies to sdk vm XXXX_VERSION.

The **ruby_workspace** folder is your workspace, you can't move it or rename it, but you can sym-link it if you want.

## Agents management
Gui interface : *http://localhost:5000/*

On this page, you can create/start/stop a project then reboot the VM's ruby server to apply your modifications.

## Agent structure
 When you have created your project in the SDK Agents tab, you will see a folder with the same name in your workspace, it looks like:

* **initial.rb** : where your code adventure starts.
* **Gemfile** : where you put the gems you need.
* **README.md** : where you explain what you do because documentation is mandatory.
* **config/** : folder where you put your configuration.
* **config/protogen.json** : configuration of messages that can be exchanged between device and server.
* **config/schedule.rb** : a *whenever* file to create your scheduled cron rules.
* **doc/** : folder where you put your documentation.
* **doc/protogen/** : folder where the protocol's documentation is generated.
* **modules/** : folder where you create your ruby modules.

You will also find in your workspace a *sdk\_logs* folder where you will find your agent's logs (file *ruby-agent-sdk-server.log*) and also the server's logs.

To test your code, just modify your code and 'apply and reboot' on the **http://localhost:5000/** web page.

The com interface runs on port 5001.

## Quickstart guide

1. In a web browser, access the page http://0.0.0.0:5000.
2. On the column "Agent name", enter a name for your new agent, then click on "Create agent". Also click on "Mount" to activate your agent.
3. In your *ruby-workspace* folder, a new folder has been created with the structure defined above.
4. Edit the *config/\<agent\_name\>.yml.example* file: you need to configure the dynamic channel(s) used by your agent, and the kind of message you want to receive (parameters 'subscribe\_presence', 'subscribe\_message' and 'subscribe\_track', see below).
5. Edit the relevant methods in the *initial.rb* file (see below).
6. You should limit *initial.rb* size: create a *lib* sub-folder in your agent folder and put your code here in .rb files.
7. Edit your *Gemfile* with the additional gems you need. They will be installed and loaded for you.
8. On the "SDK Agents" tab, click on "reboot ruby agent sdk server" to apply your changes.
9. When running your tests, check the "Server logs" tab. It contains nicely formatted logs of the agents that are currently running. If you want the raw logs, they are in the "sdk_logs" folder of your VM.
10. Complete your *README.md*.

## Important guidelines

* Your agent must be stateless, global variables are strictly forbidden.
* If you use Protogen messages, follow the Protogen guide to see how to configure your messages.
* The dynamic channel used by this agent (edit the *config/\<agent\_name\>.yml.example* file) can be defined as a string or an array of strings (see YAML documention for syntax).

## Message handling (in initial.rb)

### Receive something from a device

Depending on the messages you suscribed to in the *config/\<agent\_name\>.yml.example* file, you must implement the corresponding methods in your *initial.rb* file.

#### presence : This method is called when a connection/reconnection/deconnection happens.

``` ruby
def new_presence_from_device(presence)
  ## Write your code here
  SDK.API::log.debug('initial:new_presence_from_device')
end
```

Where *presence* is an object of the *CCS::Presence* class with the following accessors:

* **asset**   : imei of the device
* **time**    : timestamp of the event
* **bs**      : binary server source
* **type**    : 'connect' or 'reconnect' or 'disconnect'
* **reason**  : reason for the event
* **account** : account name type String
* **meta**    : a map with some meta data, generally none.


#### message: This method is called when a message is received from the device.

``` ruby
def new_msg_from_device(message)
  ## Write your code here
  SDK.API::log.debug('initial:new_message_from_device')
end
```

Where *message* is an object of the *CCS::Message* class with the following accessors:

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


#### track: This method is called when a tracking set of data is received from the device.

``` ruby
def new_track_from_device(track)
  ## Write your code here
  SDK.API::log.debug('initial:new_track_from_device')
end
```

Where *track* is an object of the *CCS::Track* class with following accessors:

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

#### order: This method is called when a schedule tasks is requested.

``` ruby
def new_order(order)
  # Write your code here
  SDK.API::log.debug('initial:new_order')
end
```
Where *order* is an object of the *CCS::Order* class with following accessors:

* **agent**        : agent name concerned by the order
* **code**         : code specified into the schedule.rb (@see Schedule tasks with cron documentation)
* **params**       : a string or parameters (@see Schedule tasks with cron documentation)


### Send something to the device

Use the *SDK.API::gate* object API (see the *API server* section of the documentation).
