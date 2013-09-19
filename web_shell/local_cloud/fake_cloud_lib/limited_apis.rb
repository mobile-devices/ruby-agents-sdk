require 'redis'

class ForbiddenApiError < StandardError
end

# @api private
module LimitedApis

  # A Redis client that forbid some commmands to be executed.
  #
  # Agents that use these commands are very likely to be refused by Mobile Devices.
  # This class points what commands should not be used by agents to help
  # developing agents that will be accepted.
  #
  # Internally, this object uses a blacklist (and not a whitelist) for simplicity
  # and because real security issues are out of the scope of this class.
  # @api private
  class SafeRedis < Redis

    # The default explanation of why a command is forbidden.
    @@DEFAULT = "This Redis command must not be used by an agent."

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
          slowlog: @@DEFAULT
        }

    # Initializes the Redis object then overrides its methods
    # @param [Array] params Parameters to pass to the {Redis::Namespace} constructor
    def initialize(*params)
      # Initialize the Redis client as usual
      super(*params)
      # Override any unwanted method
      # Get metaclass
      metaclass = class << self; self; end
      @@FORBIDDEN_METHODS.each do |meth, reason|
        # Redefine the unwanted method
        metaclass.send(:define_method, meth) do |*params|
          raise ForbiddenApiError.new("Forbidden Redis command call: #{meth}. Reason: #{reason}")
        end
      end
    end

  end # class SafeRedis

end # module LimitedApis
