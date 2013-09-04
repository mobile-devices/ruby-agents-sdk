# @markup markdown
# @title Schedule tasks with cron
# @author Xavier Demorpion

# Schedule tasks with cron #

You can schedule tasks to be executed on a regular basis. To do this you need to edit the `config/schedule.rb` file.

In this example we will send an order 'refresh' to the agent every day at 1am.

We use the ruby gem `whenever` to configure cron, by editing `config/schedule.rb`:

``` ruby
# Define here your agent scheduled callbacks

# Examples:

# every 2.hours do
#   execute_order "66"
# end

# every 1.day, :at => '4:30 am' do
#   execute_order "refresh", :params => "parameters"
# end

# You MUST use the SDK 'execute_order' command, other whenever basic commands like 'runner', 'rake' or 'command' will be rejected.

# Learn more about whenever: http://github.com/javan/whenever

every 1.day, :at => '1:00 am' do
  execute_order "refresh"
end
```

`execute_order` is a command defined by the SDK and will be the only accepted command.

The in our `initial.rb` we define the `refresh` callback:

``` ruby
module Initial_my_agent

  # ...

  def refresh
    # do stuff
  end

end
```

Read the [whenever documentation](https://github.com/javan/whenever) to see how you can configure when your orders are called.

Once you have edited this file and rebooted the server, you will be able to test the task by using the appropriate button in the 'Scheduled cron tasks' view in the project tab.
