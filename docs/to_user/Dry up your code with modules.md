If you want to dry up your code in the initial.rb (and you should), you should create ruby modules.

Let's create a 'MyAgentModule' module for our agent 'tracking_agent'.


modules/MyAgentModule.rb:

``` ruby
module MyAgentModule
  def do_stuff_from_my_module()
    # do stuff
  end

end
```

initial.rb:

``` ruby
require_relative 'modules/my_agent_module'

module Initial_agent_tracking_agent
  include MyAgentModule

  def new_presence_from_device(meta, payload, account)
  end

  def new_message_from_device(meta, payload, account)
    msg = Message.new(payload)
  end

  def new_track_from_device(meta, payload, account)
    do_stuff_from_my_module
  end

end
```

