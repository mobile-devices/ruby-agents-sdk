#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Tools

      class ProtogenClass

        def initialize(apis)
          @user_apis = apis
          begin
            @protogen_apis = Object.const_get("Protogen_#{apis.user_class.agent_name}")::ProtogenAPIs
            @protogen_domain = Object.const_get("Protogen_#{apis.user_class.agent_name}")
          rescue
            @protogen_apis = nil
            @protogen_domain = nil
          end
        end

        def user_api
          @user_apis
        end

        def protogen_apis
          @protogen_apis
        end

        def protogen_domain
          @protogen_domain
        end


        # @api private
        # this helper provide Messages ready to be sent to the outside from a Protogen Object
        def protogen_encode(raw_protogen_class)
          msg = raw_protogen_class.clone
          if protogen_apis != nil
            begin
              encoded = self.protogen_apis.encode(msg)

              # useless tests ?
              if encoded.is_a? String
                msg.content = encoded
                user_api.mdi.tools.log.info("Protogen content is simple string")
                return [msg]
              elsif encoded.is_a? Array
                user_api.mdi.tools.log.info("Protogen content is an array of size #{encoded.size}")
                fragments = encoded.map do |content|
                  frg = msg.clone
                  frg.id = CC.indigen_next_id(frg.asset)
                  frg.content = content
                  frg
                end
                # the last fragment id must be the original message id
                # for proper response detection
                fragments.last.id = msg.id
                return fragments
              else
                raise "message push protogen unknown encoded type : #{encoded.type}"
              end

            rescue => e
              if $allow_protogen_fault
                user_api.mdi.tools.log.warn("CloudConnectServices:Messages.push: unknown protogen message type because #{e.inspect}")
                return [msg]
              else
                raise e
              end
            end
          else
            if $allow_non_protogen
              user_api.mdi.tools.log.warn('CloudConnectServices:Messages.push: ProtogenAPIs not defined')
              return [msg]
            else
              raise "No Protogen defined"
            end
          end
        end

      end

    end
  end
end
