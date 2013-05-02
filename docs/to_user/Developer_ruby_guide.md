
# Ruby agent sdk developer guide

The folder ruby_workspace is your workspace, you can't move it or rename it, but you can sym-link it if you want.

## I) Project managment
To manage projects, go to http://localhost:5000/ with your favourite browser (you shall use the is of the VM's host instead of 'localhost' in order to access through network).

On this page, you can create/start/stop project then apply and reboot VM's ruby server to apply your modifications.

## II) Project structure
 When you have created your project you will see a folder of the same name into your workspace, it's look like :

* initial.rb : where your code adventure starts
* Gemfile : where your put gems you need
* README.md : where you explain what you do because documentation is mendatory
* config/ : folder where you put your configuration
* cron_tasks/ : folder where you will put your cron task needed for your agent.

You will also find into your workspace a sdk_logs where you find your agent's logs and also servers logs.

To test your code, just modify your code and 'apply and reboot' onto the http://localhost:5000/ web page.

The com interface run onto the 5001 port.

#### General guide-line :

* You receive the messages into the initial.rb, you shall include your code into some sub .rb file into the lib folder.
* Do your agent stateless
* To configure the dynamic channel used by this agent, go and edit config/dynamic_channel.yml
* If you need additional gems, edit the GemFile and require them here
* Remember to complete the README.md
* To write some log, use the @logger object (class Logger)


## III) Message handling

### A) Receive something from device (@see initial.rb)

#### A1) presence : This method is called when a connection/reconnection/deconnection happen.

def new_presence_from_device(meta, payload, account)
  # Write your code here
  @logger.debug('initial:new_presence_from_device')
end

 With :

"**meta**", a map with some meta data, generally none.

"**payload**", a map with :

    * asset   : imei of device
    * time    : timestamp of the event
    * bs      : binary server source
    * type    : 'connect' or 'reconnect' or 'disconect'
    * reason  : reason from device

"**account**" (account name type String).

#### A2) message : This method is called when a message is received from the device.

def new_message_from_device(meta, payload, account)
  msg = Message.new(payload)
  # Write your code here
  @logger.debug('initial:new_message_from_device')
end

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

#### A3) track : This method is called when a tracking set of data is received from the device.

def new_track_from_device(meta, payload, account)
  # Write your code here
  @logger.debug('initial:new_track_from_device')
end

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


### B) Send something to device

#### B1) push message to device

Use send_message_to_device(account, asset, content)

With :

"**account**" (account name type String).

"**asset**" (imei type integer).

"**content** (binary content, or string, or map)

#### B2) reply a message to device

Use reply_message_to_device(message, account, content)

"**message**" (message to reply to, type message).

"**account**" (account name type String).

"**content** (binary content, or string, or map)
