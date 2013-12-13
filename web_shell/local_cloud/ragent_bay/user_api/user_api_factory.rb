#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'digest/md5'
require_relative 'user_api'

module UserApiFactory

  def self.gen_user_api(user_class, env)
    env_md5 = Digest::MD5.hexdigest(env.sort.to_s)
    @@mdi_apis ||= {}
    @@mdi_apis[env_md5] ||= begin
      p "create user api for env #{env_md5}"
      UserApiClass.new(user_class, env, env_md5)
    end
  end

  def self.get_created_envs
    @@mdi_apis
  end

end

USER_API_FACTORY = UserApiFactory