# @markup markdown
# @title FAQ
# @author Xavier Demorpion

# Frequently asked questions #

## Code snippets ##

### How do I create a new `Message` (for injecting it in the cloud for instance)? ###

```ruby
module Example
  include Sdk_api_my_example_agent

  def do_something
    msg = SDK.CCS::Message.new
    msg.content = "hello world"
    msg.channel = "com.mdi.services.injector"
    # ... see the CCS::Message documentation
  end

end
```

### How do I log an exception? ###

```ruby
module Example
  include Sdk_api_my_example_agent

  begin
    42/0
  rescue ZeroDivisionError => e
    SDK.CCS.print_ruby_exception(e)
  end
end
```

## Understanding the logs ##

### When I send a message to the server, what is the triggered sequence of events? ###

For each of these items there is a corresponding box in the left column of the "logs" tab:

1. The server receives the message, with a temporary ID set by the device.
2. The server generates a message ID and send an ACK to the device with the mapping "temporary ID - message ID"
3. It sets the incoming message ID to this message ID and dispatch this message to the agent that is listening on the message channel.
4. The corresponding callback of the agent is run.

### What are all these warnings about Protogen? Should I worry about them? ###

As of now, {guides/protogen.md Protogen} tries to encode/decode every outgoing/incoming message. If it fails, the SDK logs a warning and go on handling the message as a non-Protogen one.

If you are not using Protogen, then you can ignore these messages. However, if you see these messages for a Protogen message, then something is going wrong.