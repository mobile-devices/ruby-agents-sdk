#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module UserApis
  module Mdi
    module Tools
      # A generic subscriber class tool
      class SubscriberClass < Struct.new(:classes)

        def initialize(apis = nil)
          @user_apis = apis
          self.classes = []
        end

        def user_api
          @user_apis
        end

        def subscribe(user_class)
          self.classes << user_class
        end

        def get_subscribers
          self.classes
        end

      end

    end
  end
end
