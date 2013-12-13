#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Storage

      class TrackFieldMappingClass

        def initialize(apis)
          @user_apis = apis
        end

        def user_api
          @user_apis
        end

        # return a field struct
        def get_by_id(int_id, no_error)
          RagentApi::TrackFieldMapping.get_by_id(int_id, user_api.account, no_error)
        end

        # return a field struct
        def get_by_name(str_name, no_error)
          RagentApi::TrackFieldMapping.get_by_name(str_name, user_api.account, no_error)
        end

      end

    end #Storage
  end #Mdi
end #UserApis
