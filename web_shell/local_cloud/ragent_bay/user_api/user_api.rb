#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require_relative 'com/user_api_included'

class UserApiClass

  def initialize(user_class, env, md5env)
    @USER_CLASS = user_class
    @USER_AGENT_CLASS_ENV = env
    @USER_AGENT_CLASS_ENV_MD5 = md5env

    CC.logger.debug("creating new user api of #{@USER_CLASS} with env #{env} with md5api='md5env'")
  end

  def user_class
    @USER_CLASS
  end

  def user_environment
    @USER_AGENT_CLASS_ENV
  end

  def user_environment_md5
    @USER_AGENT_CLASS_ENV_MD5
  end

  def account
    @ACCOUNT ||= user_environment['account']
  end

  def agent_name
    @AGENT_NAME ||= user_environment['agent_name']
  end

  def running_env_name
    @RUNNING_ENV_NAME ||= user_environment['running_env_name']
  end

  include UserApiIncluded

end

# env = {
#   'root' => 'yes',
#   'owner' => 'ragent',
#   'agent_name' => 'ragent'
# }

$SDK_API = nil # = UserApiClass.new(nil,nil, nil)

# constant api chaned on each message
def set_current_user_api(api)
  #const_set('SDK_API', api)
  $SDK_API = api
end
