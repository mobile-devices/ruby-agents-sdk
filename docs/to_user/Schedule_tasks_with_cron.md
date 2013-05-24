In this example, we want to call 'do\_stuff\_from\_my\_module' method into the module MyAgentModule every day at 1 am.


### Example project setup

modules/MyAgentModule.rb :

``` ruby
module MyAgentModule
  def do_stuff_from_my_module()
    # do stuff
  end

end
```

initial.rb :

``` ruby
require_relative 'modules/my_agent_module'

module Initial_agent_tracking_agent
  include My_agent_module

  def new_presence_from_device(meta, payload, account)
  end

  def new_message_from_device(meta, payload, account)
    msg = Message.new(payload)
  end

  def new_track_from_device(meta, payload, account)

  end

end
```

### Task creation

Then I create a file script that will be called by cron, namely cron\_tasks/my\_tasks.rb:

``` ruby
#!/usr/bin/ruby -w
$daemon_cron_name = __FILE__
require_relative '../../../web_shell/agents_generator/cloud_agents_generated/generated'

# the object $tracking_agent_initial will allow me to access my code :
$tracking_agent_initial.do_stuff_from_my_module
```

to test the task, you can run :

``` bash
ruby cron_tasks/my_tasks.rb
```

### Cron configuration using whenever

Finally I use the whenever file to configure cron, namely config/schedule.rb:

``` ruby
cron_tasks_folder = File.dirname(File.expand_path(__FILE__)) + '/../cron_tasks'

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# every 2.hours do
#   command "ruby #{cron_tasks_folder}/my_ruby_task.rb"
# end
#
# every 1.day, :at => '4:30 am' do
#   command "ruby #{cron_tasks_folder}/my_ruby_task.rb"
# end

# Learn more: http://github.com/javan/whenever

every 1.day, :at => '1:00 am' do
  command "ruby #{cron_tasks_folder}/my_tasks.rb"
end

```

@see [whenever documentation](https://github.com/javan/whenever) to see configuration you can make

ps : you can only use 'command' and not 'rake' or 'runner' for whenever, because you don't have an easy accès of the sdk's Gemfile.
