
In the [Beginner documentation](http://0.0.0.0:5000/doc#toc_1) you saw you can manage scheduled orders.

Here we will see how to trigger those orders.

In this example we will send an order 'refresh' to the agent every day at 1am.


We use **whenever** to configure cron, by editing *config/schedule.rb*:

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

Read the [whenever documentation](https://github.com/javan/whenever) to see how you can configure when your orders are called.

Once you have edited this file and rebooted the serveur, you will be able to test the task by using the appropriate button in the 'Scheduled cron tasks' view in the project tab.
