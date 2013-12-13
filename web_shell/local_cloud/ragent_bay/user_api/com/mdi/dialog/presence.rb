#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Dialog
      # An event received when a device change its connection status
      # @api public
      class PresenceClass < Struct.new(:asset, :time, :bs, :type, :reason, :account, :meta)

        # ---
        # Presence hash :
        # "meta", a map with some meta data, generally none.
        # "payload", a map with :
        #   asset : imei of the device
        #   time : timestamp of the event
        #   bs : binary server source
        #   type : 'connect' or 'reconnect' or 'disconnect'
        #   reason : reason for the event
        # "account" (account name type String).
        # +++

        # @!attribute [rw] asset
        #   @api public
        #   @return [String] the IMEI of the device or other similar unique identifier.

        # @!attribute [rw] time
        #   @api public
        #   @return [Fixnum] a timestamp indicating when this event was received.

        # @!attribute [rw] bs
        #   @api public
        #   @return [String] the identifier of the source binary server (entry point of the MDI cloud).

        # @!attribute [rw] type
        #   @api public
        #   @return [String] 'connect', 'reconnect' or 'disconnect'.

        # @!attribute [rw] reason
        #   @api public
        #   @return [String] the reason for the event.

        # @!attribute [rw] meta
        #   @api public
        #   @return [Hash] some meta data associated with the event (may be empty).

        # @!attribute [rw] account
        #   @api public
        #   @return [String] the account name used.

        # Constructor.
        #
        # Hash representation of a presence:
        #
        #   ``` ruby
        #   {
        #   meta => {
        #     'account' => self.account,
        #   },
        #   payload => {
        #     'asset' => self.asset,
        #     'time' => self.time,
        #     'bs' => self.bs,
        #     'type' => self.type,
        #     'reason' => self.reason
        #   }
        #   ```
        #
        def initialize(apis, struct = nil)
          @user_apis = apis

          if struct.blank?
            self.meta = {}
            self.type = 'connect'
          else

            self.meta = struct['meta']
            payload = struct['payload']
            self.asset = payload['asset']
            self.time = payload['time']
            self.bs = payload['bs']
            self.type = payload['type']
            self.reason = payload['reason']
            self.account = meta['account']

          end

          if type != 'connect' && type != 'reconnect' && type != 'disconnect' && type != 'failed_connect'
            raise "Wrong type of presence : #{type}"
          end

        end

        def user_api
          @user_apis
        end

        # Returns a hash representation of the event.
        # See the constructor documentation for the format.
        # @return a hash representation of the event.
        # @api private
        def to_hash
          r_hash = {}
          r_hash['meta'] = self.meta
          r_hash['payload'] = {
            'asset' => self.asset,
            'time' => self.time,
            'bs' => self.bs,
            'type' => self.type,
            'reason' => self.reason
          }
          r_hash.delete_if { |k, v| v.nil? }
        end


      end #Presence
    end #Dialog
  end #Mdi
end #UserApis
