#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Dialog
      class OrderClass < Struct.new(:agent, :code, :params)

        def initialize(apis, struct = nil)
          @user_apis = apis

          if struct == nil
            raise "Order need a struct to be initialized"
          else
            self.agent = struct['agent']
            self.code = struct['order']
            self.params = struct['params']

            agent = RAGENT.get_agent_from_name(struct['agent'])
            if agent == nil
              raise AgentNotFound , "Server: agent #{self.agent} is not running on this bay"
            end
          end
        end

        def user_api
          @user_apis
        end

        # @return a hash representation of this order. See constructor documentation for format.
        # @api private
        def to_hash
          r_hash = {}
          r_hash['agent'] = self.agent
          r_hash['order'] = self.order
          r_hash['params'] = self.params
          r_hash.delete_if { |k, v| v.nil? }
        end





      end #OrderClass
    end #Dialog
  end #Mdi
end #UserApis
