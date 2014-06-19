#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'logger'
require_relative 'limited_apis'
require_relative 'file_interface'
require 'redis-namespace'
require 'time'
require 'httpclient'
require 'mongo'

# Cloud connect SDK Side Implementation

module CloudConnectSDK


  def self.instance
    'dev'
  end

  module RagentHttpApiV3
    def self.request_http_cloud_api(account, service)
      nil
    end
  end

  module NavServer
    class << self

      def url
        @url ||= "http://localhost:4567"
      end

      def get_query(service_url_suffix)
        @http_client ||= HTTPClient.new
        CC.logger.debug("http get request '#{url}/#{service_url_suffix}'")
        resp = @http_client.get("#{url}/#{service_url_suffix}")
        # error?
        if resp.status_code != 200
          raise "NavServer response status = #{resp.status_code}"
        end
        JSON.parse(resp.body,symbolize_names: true)
      end

      def post_query(service_url_suffix, body)
        @http_client ||= HTTPClient.new
        CC.logger.debug("http post request '#{url}/#{service_url_suffix}'")
        resp = @http_client.post("#{url}/#{service_url_suffix}", body)
        # error?
        if resp.status_code != 200
          raise "NavServer response status = #{resp.status_code}"
        end
        JSON.parse(resp.body,symbolize_names: true)
      end


    end # class << self
  end

  @@indigen_id = 0

  # wrapper from indigen
  def self.indigen_next_id(key = 'default')

    #todo : if VMProd, don't gen it
    @epoch ||= Time.parse("2010-01-01T00:00:00Z")
    t = Time.now - @epoch.to_i
    ts = ((t.to_f * 1000).floor.to_s(2)).rjust(42,'0')
    c  = @@indigen_id.to_s(2).rjust(8, '0')
    if @@indigen_id == 255
      @@indigen_id = 0
    else
      @@indigen_id = @@indigen_id + 1
    end
    wid = '00000000000000'
    genid = (ts + c + wid)
    genid.to_i(2)
  end

  def self.logger
    @logger ||= begin
      if File.directory? '../../logs/'
        log_path = '../../logs/ruby-agent-sdk-server.log'
      elsif $daemon_cron_name != nil
        log_path = "./cron_#{$daemon_cron_name}.log"
      else
        log_path = './daemon_ruby.log'
      end

      @logger = Logger.new(log_path, 50, 4 * 1024 * 1024)
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @logger.formatter = Logger::Formatter.new
      @logger
    end
  end

  def self.redis
    @redis ||= LimitedApis::SafeRedis.new(:host => 'localhost', :port =>  '7879')
  end

  def self.mongoClient
    @mongoClient ||= Mongo::MongoClient.new
  end

  def self.instance
    :development
  end

  # send outside the cloud
  def self.push(hash_msg, queue = nil)

    # set the recorded at like the read server would do
    hash_msg['recorded_at'] = Time.now

    # inject case
    if queue == 'presences'
      Thread.start {
        json_msg = hash_msg.to_json
        sleep(1)
        command = "curl -i -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d '#{json_msg}' http://localhost:5001/presence"
        `#{command}`
      }

    elsif queue == 'messages'
      Thread.start {
        json_msg = hash_msg.to_json
        sleep(1)
        command = "curl -i -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d '#{json_msg}' http://localhost:5001/message"
        `#{command}`
      }

    elsif queue == 'tracks'
      Thread.start {
        json_msg = hash_msg.to_json
        sleep(1)
        command = "curl -i -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d '#{json_msg}' http://localhost:5001/track"
        `#{command}`
      }

    elsif queue == 'collections'
      Thread.start {
        json_msg = hash_msg.to_json
        sleep(1)
        command = "curl -i -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d '#{json_msg}' http://localhost:5001/collection"
        `#{command}`
      }


    else
      push_something_to_device(hash_msg)
    end
  end

end

CC = CloudConnectSDK