#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'logger'
require 'redis'
require 'redis-namespace'

# Cloud connect SDK Side Implementation

module CloudConnectSDK
  # wrapper from indigen
  require 'time'
  def self.indigen_next_id()

    #todo : if VMProd, don't gen it
    @epoch ||= Time.parse("2010-01-01T00:00:00Z")
    t = Time.now - @epoch.to_i
    ts = ((t.to_f * 1000).floor.to_s(2)).rjust(42,'0')
    c  = '00000000'
    wid = '00000000000000'
    genid = (ts + c + wid)
    genid.to_i(2)
  end

  def self.logger()
    @logger ||= begin
      if File.directory? '../../logs/'
        log_path = '../../logs/ruby-agent-sdk-server.log'
      elsif $daemon_cron_name != nil
        log_path = "./cron_#{$daemon_cron_name}.log"
      else
        log_path = './daemon_ruby.log'
      end

      @logger = Logger.new(log_path, 10, 200 * 1024 * 1024)
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @logger.formatter = Logger::Formatter.new
      @logger
    end
  end

  def self.redis()
    @redis ||= Redis.new(:host => 'localhost', :port =>  '7879')
  end

  # send outside the cloud
  def self.push(hash_msg)

    # set the recorded at like the read server would do
    hash_msg['recorded_at'] = Time.now

    push_something_to_device(hash_msg)
  end

end

CC = CloudConnectSDK