#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

#todo: could be generated

require_relative 'mdi/dialog/dialog'
require_relative 'mdi/storage/storage'
require_relative 'mdi/tools/tools'



module UserApis
  class MdiClass

    def initialize(apis)
      @user_apis = apis
    end

    def user_api
      @user_apis
    end

    def dialog
      @dialog ||= Mdi::DialogClass.new(user_api)
    end

    def storage
      @storage ||= Mdi::StorageClass.new(user_api)
    end

    def tools
      @tools ||= Mdi::ToolsClass.new(user_api)
    end

  end
end


module UserApiIncluded

  def mdi
    @mdi ||= UserApis::MdiClass.new(self)
  end

end
