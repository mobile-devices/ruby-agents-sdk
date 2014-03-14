# @markup markdown
# @title Guidelines
# @author Xavier Demorpion

# Guidelines #

There are a few guidelines your agent must follow if it is to run correctly on the MDI infrastructure.

## Stateless agents ##

Your agent must be stateless.

In other words, the actions trigerred by an event depends only on the nature of the event (and the data it carries) and not on the previous processed events.

You must not use global variables or similar patterns (class variables, module variables...) to store data between two requests.

The reason for this is that your agent will live in a cloud where multiple instances of your agent will run simultaneously. These instances can not share data between themselves. Any instance of your agent can be restarted at any time. You can not know which instance of your agent will receive a given device message.

If you need some kind of "history" in your agent, you must attach this history to the messages exchanged. Cookies in messages (see the {file:guides/protogen.md Protogen guide}) are a way of implementing this.

## Use the provided API ##

The VM gives you access to the API to interact with a redis database, to write logs... If you want to interact with a redis database or write logs, please use this API and not your custom solution.

Still, the SDK is an open environment and you can use your own Ruby solutions. Note however that any of your custom solutions can be subject to validation before being accepted by MDI.

## Anti-patterns (mistakes to avoid)

### Redis

Several instances of your agent may or may not share the same Redis cache. You can access the Redis cache with `user_api.mdi.storage.redis`.

#### Storing state or sharing data in the Redis cache

It can be tempting to store information in the Redis cache to be used to process the next device message. For instance, the device sends message A, your agent stores message A in Redis, then the device sends message B, and your agent retrieves message A from Redis to help processing message B.

Such a pattern may not work depending on the production environment configuration, because: 

* several instances of your agent may not share the same Redis cache
* you can not know which instance of your agent will receive a given message.

So in the above example, what if you have several instances of your agent, one receiving message A, and one receiving message B? The message B will not be processed because message A will not be in the cache of the agent receiving the message.

In other words: your agent must be **stateless**. It is OK to cache data to speed up some processing task, but you must always provide a way to process a message if the cache is not available.

#### Not taking into account Redis concurrent access issues

On the other hand, several instances of your agent *may* share the same Redis instance, so an agent can cache data to be used by other agents (but as stated above, do not rely on it).

However, this means you have to take concurrent access issues into account when using Redis, as several instances of your agent may use the same cache. For instance, the following code snippet may not work as intended:

```ruby
some_data = some_function(redis.get("some_key"))
if some_data.needs_update?
  redis.del("some_key")
  redis.del("some_other_dependant_key")
  new_data = compute_some_new_data
  redis.set("some_key", new_data.value)
  redis.set("some_other_dependant_key", new_data.dependance)
end
some_dependant_data = redis.get("some_other_dependant_key")
```

If one instance thinks the data is obsolete while it is not for another one, and the first instance deletes the "some_other_dependant_key" key just before the other instance reads it, there may be a problem.

You may want to look into the `MULTI/EXEC/DISCARD`, `WATCH/UNWATCH` or `SETNX` commands (for instance) to solve this kind of problems.

## Other useful information ##

### Logs ###

In production environments, ony log levels "information", "warning" and "error" are actually written. "debug" log level is discarded.

You should use the correct log level to have useful and helpful logs:

- `log.debug` is meant to display very detailed information about the inner workings of your agent. You can use it in debug phases to print variable values or other detailed information that helps you ensuring that your agent is doing what you're expecting it to do, without worrying that this information will clutter your production log file.
- `log.info` is a higher level of logging used to print information about what your agent is doing. Such logs are expected to be useful to check at which point of the processing of a message your agent is.
- `log.warn` is used to log warnings about something that shouldn't have happened.
- `log.error` is used to log errors that your agent can handle.
- `log.fatal` is used to log errors that your agent can not handle (so your agent will abort its processing after encountering such an error).

Correct usage of logs will greatly help you debug your agent both in your development phase and in the production phase.

### Exceptions ###

Any exception raised by your agent and not caught by your code will be caught by the SDK and displayed in the logs. In a real cloud environment, such exceptions indicate a critical failure of your agent and will send an alert so it is possible to detect it early.

You can use this process to manage your error handling: catch only the exceptions your agent can recover from. If your agent encounters a situation it can not handle, let the exceptions pass so it will be easy to detect the failure.

For instance, let's say you have an agent that queries an external web API by HTTP. If this query fails because the web API is down, you could handle this error by looking in a cache. If you can not access this cache, then you could decide to raise an exception. Your agent will fail and it will be clear that an error needing an imediate fix had happened.

Bottom line: do not worry too much about catching your exceptions.

On the other hand, *never* silence exceptions (silencing an exception is catching it then not acting upon it). At least log the exception before moving on (there is a nice method to display an exception with its stack trace: {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.print_ruby_exception SDK.API.print_ruby_exception}) along with information about why this exception can be ignored. Not doing so will make your agent very difficult to debug when it will encounter an unusual situation in a production environment.