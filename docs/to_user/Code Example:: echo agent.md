
An echo agent is an agent that replies with the message received.

``` ruby
def new_message_from_device(meta, payload, account)
  msg = Message.new(payload)
  reply_message_to_device(msg,account,msg.payload)
end
```
