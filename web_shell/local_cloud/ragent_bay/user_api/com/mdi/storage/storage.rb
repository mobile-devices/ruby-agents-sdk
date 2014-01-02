#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require_relative 'tracking_field_mapping'

module UserApis
  module Mdi

    class StorageClass

      def initialize(apis)
        @user_apis = apis
      end

      def user_api
        @user_apis
      end

      def redis(id = 'default')
        @user_redis ||= {}
        @user_redis[id] ||= Redis::Namespace.new("RR:#{user_api.agent_name}_#{id}", :redis => CC.redis)
      end

      def tracking_fields_info
        @tracking_fields_info ||= Storage::TrackFieldMappingClass.new(user_api)
      end

      def config
        @config ||= user_api.user_class.user_config
      end

      def agent_root_path
        user_api.user_class.root_path
      end

    end

  end
end
