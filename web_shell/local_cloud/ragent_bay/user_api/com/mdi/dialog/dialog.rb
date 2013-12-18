#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require_relative 'presence'
require_relative 'message'
require_relative 'track'
require_relative 'order'
require_relative 'cloud_gate'
require_relative 'device_gate'


module UserApis
  module Mdi

    class DialogClass

      def initialize(apis)
        @user_apis = apis
      end

      def user_api
        @user_apis
      end

      # @private
      def create_new_presence(struct = nil)
        Dialog::PresenceClass.new(user_api, struct)
      end

      # @private
      def create_new_message(struct = nil)
        Dialog::MessageClass.new(user_api, struct)
      end

      # @private
      def create_new_track(struct = nil)
        Dialog::TrackClass.new(user_api, struct)
      end

      # @private
      def create_new_order(struct = nil)
        Dialog::OrderClass.new(user_api, struct)
      end

      def device_gate
        Dialog::DeviceGateClass.new(user_api, user_api.user_class.managed_message_channels[0])
      end

      def cloud_gate
        Dialog::CloudGateClass.new(user_api, user_api.user_class.managed_message_channels[0])
      end

    end

  end
end
