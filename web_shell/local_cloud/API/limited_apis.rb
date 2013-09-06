require 'redis-namespace'

class ForbiddenApiError < StandardError
end

module LimitedApi

  # A wrapper around a Redis API that forbid some commmands to be executed.
  #
  # Agents that use these commands are very likely to be refused by Mobile Devices.
  # This class points what commands should not be used by your agent to help you
  # develop agents that will be accepted.
  #
  # Internally, this object uses a blacklist (and not a whitelist) for simplicity
  # and because real security issues are out of the scope of this class.
  # @api private
  class RedisNamespaced

    # The default explanation of why a command is forbidden.
    @@DEFAULT = "This Redis command must not be used by your agent."

    # A Hash whose keys are the name (as symbols) of the forbidden methods
    # and values are the reason of why the commend is forbidden.
    @@FORBIDDEN_METHODS = {
          bgrewriteaof: @@DEFAULT,
          bgsave: @@DEFAULT,
          config: @@DEFAULT,
          debug: @@DEFAULT,
          flushall: @@DEFAULT,
          flushdb: @@DEFAULT,
          migrate: @@DEFAULT,
          quit: @@DEFAULT,
          save: @@DEFAULT,
          select: @@DEFAULT,
          shutdown: @@DEFAULT,
          slaveof: @@DEFAULT,
          slowlog: @@DEFAULT,
          sync: @@DEFAULT,
          synchronize: @@DEFAULT
        }

    # Initializes the internal Redis object with the given parameters
    # @param *params Parameters to pass to the {Redis::Namespace} constructor
    def initialize(*params)
      @redis ||= Redis::Namespace.new(*params)
    end

    # Check if the method call is legal and if so, forward it to the inner Redis instance
    def method_missing(meth, *args, &block)
      if @@FORBIDDEN_METHODS.has_key?(meth)
        raise ForbiddenApiError.new("Forbidden Redis command call: #{meth}. Reason: #{@@FORBIDDEN_METHODS[meth]}")
      else
        @redis.send(meth, *args, &block)
      end
    end

  end # class RedisNamespaced

end # module LimitedApis
