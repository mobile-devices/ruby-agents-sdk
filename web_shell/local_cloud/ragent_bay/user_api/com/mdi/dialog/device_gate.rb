#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Dialog

      # @api public
      # This class handles outgoing communications from the cloud.
      # @note You don't have to instantiate this class yourself.
      #       Use the {Sdk_api_XX_DOWNCASED_CLEAN_PROJECT_NAME::SDK::API.device_gate SDK.API.device_gate} object which is already configured for your agent.
      class DeviceGateClass

        # @api private
        # @param channel [String] the messages passing through this gate will be sent on this channel
        def initialize(apis, default_send_channel)
          @user_apis = apis
          @default_send_channel = default_send_channel
        end

        def user_api
          @user_apis
        end

        # Push a message to the device.
        # @param asset [Fixnum] the asset the message will be sent to
        # @param account [String] account name to use
        # @param content [Object] content of the message
        def push(asset, account, content, channel = @default_send_channel)
          begin
            PUNK.start('push','pushing msg ...')

            msg = user_api.mdi.dialog.create_new_message({
              'meta' => {
                'account' => account
                },
              'payload' => {
                'type' => 'message',
                'sender' => '@@server@@',
                'recipient' => asset,
                'channel' =>  channel,
                'payload' => content,
                'asset' => asset
              }
            })
            user_api.mdi.tools.protogen.protogen_encode(msg).each {|message| message.push}
            # success !
            PUNK.end('push','ok','out',"SERVER -> MSG[#{crop_ref(msg.id,4)}]")


            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['push_sent_to_device'] += 1
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['total_sent'] += 1
          rescue Exception => e
            user_api.mdi.tools.log.error("Error on push")
            user_api.mdi.tools.print_ruby_exception(e)
            PUNK.end('push','ko','out',"SERVER -> MSG")
            # stats:
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['err_on_push'] += 1
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['total_error'] += 1
          end
        end

        # Reply a message to the device.
        # @param msg [CloudConnectServices::Message] message to reply to
        # @param content [Object] content of the message
        # @param cookies [String] optional cookies, see the {file:guide/protogen.md Protogen guide}
        def reply(of_msg, content, cookies = nil)
          begin
            PUNK.start('reply','replying msg ...')
            response = of_msg.clone
            response.parent_id = of_msg.id
            response.id = CC.indigen_next_id(response.asset)
            response.content = content
            response.meta['protogen_cookies'] = cookies
            response.sender = '@@server@@'
            response.recipient = of_msg.asset
            user_api.mdi.tools.protogen.protogen_encode(response).each {|message| message.push}
            # success !
            PUNK.end('reply','ok','out',"SERVER -> MSG[#{crop_ref(response.id,4)}] [reply of #{crop_ref(of_msg.id,4)}]")
            # stats:
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['reply_sent_to_device'] += 1
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['total_sent'] += 1
          rescue Exception => e
            user_api.mdi.tools.log.error("Error on reply")
            user_api.mdi.tools.print_ruby_exception(e)
            PUNK.end('reply','ko','out',"SERVER -> MSG (reply)")
            # stats:
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['err_on_reply'] += 1
            SDK_STATS.stats['agents'][user_api.user_class.agent_name]['total_error'] += 1
          end
        end

      end

    end
  end
end
