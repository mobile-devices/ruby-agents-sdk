#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require_relative 'log'
require_relative 'subscriber'
require_relative 'protogen'


module UserApis
  module Mdi

    class ToolsClass

      def initialize(apis)
        @user_apis = apis
      end

      def user_api
        @user_apis
      end

      def print_env_info
        p user_api.user_environment
      end

      def print_ruby_exception(e, stack_len = 20)
        stack=""
        e.backtrace.take(stack_len).each do |trace|
          stack+="  >> #{trace}\n"
        end
        log.error("  RUBY EXCEPTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n >> #{e.inspect}\n\n#{stack}\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
      end

      def log
        @log ||= Tools::LogClass.new(user_api)
      end

      def create_new_subscriber
        Tools::SubscriberClass.new(user_api)
      end

      def protogen
        @protogen ||= Tools::ProtogenClass.new(user_api)
      end

    end

  end
end
