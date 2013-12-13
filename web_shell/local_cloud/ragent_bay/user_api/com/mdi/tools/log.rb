#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module UserApis
  module Mdi
    module Tools

      class LogClass

        def initialize(apis)
          @user_apis = apis
          if user_api.user_environment['owner'] == 'ragent'
            @head = "Server: "
          else
            @head = "Agent '#{user_api.agent_name}': "
          end
        end

        def user_api
          @user_apis
        end

        def debug(str_msg)
          CC.logger.debug("#{@head}#{str_msg}")
        end

        def info(str_msg)
          CC.logger.info("#{@head}#{str_msg}")
        end

        def warn(str_msg)
          CC.logger.warn("#{@head}#{str_msg}")
        end

        def error(str_msg)
          CC.logger.error("#{@head}#{str_msg}")
        end

      end

    end
  end
end
