#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'logger'
require 'redis'
require 'redis-namespace'


module CloudConnectSDK
  # wrapper from indigen
  require 'time'
  def indigen_next_id()

    #todo : if VMProd, don't gen it
    @epoch ||= Time.parse("2010-01-01T00:00:00Z")
    t = Time.now - @epoch.to_i
    ts = ((t.to_f * 1000).floor.to_s(2)).rjust(42,'0')
    c  = '00000000'
    wid = '00000000000000'
    genid = (ts + c + wid)
    genid.to_i(2)
  end

  def logger()
    @logger ||= begin
      @logger = Logger.new('../../logs/ruby-agent-sdk-server.log', 10, 1 * 1024 * 1024)
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @logger.formatter = Logger::Formatter.new
      @logger
    end
  end

  def redis()
    #@redis ||= Redis.new('localhost', '7879')
    @redis ||= Redis.new(:host => 'localhost', :port =>  '7879')
  end
end

CC_SDK = CloudConnectSDK