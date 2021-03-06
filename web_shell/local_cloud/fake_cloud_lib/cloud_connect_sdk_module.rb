#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'logger'
require_relative 'limited_apis'
require_relative 'file_interface'
require_relative 'track_cache'
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

    def self.request_http_cloud_api_put(account, service, payload)
      true
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
    @mongoClient ||= Mongo::Client.new(['localhost:27017'])
  end

  def self.instance
    :development
  end

  # send outside the cloud
  def self.push(hash_msg, queue = nil)

    # set the recorded at like the read server would do
    hash_msg['recorded_at'] = Time.now

    if queue.nil?
      push_something_to_device(hash_msg)
      return
    end

    http = Net::HTTP.new("localhost", 5001)

    ressource =
      case queue
      when "presences"
        "/presence"
      when "messages"
        hash_msg['payload']['payload'] = Base64.encode64(hash_msg['payload']['payload'])
        "/message"
      when "tracks"
        "/track"
      when "collections"
        "/collection"
      else
        CC.logger.warn( "Unknown queue name: '#{queue}', expected one of: presences, messages, tracks, collections") # should never happen
        return
      end

    request = Net::HTTP::Post.new(ressource, "Content-type" => "application/json", "Accept" => "application/json")
    request.body = hash_msg.to_json



    Thread.start do
      begin
        sleep 3
        CC.logger.info("push http to vm:\n #{hash_msg.to_json}")
        http.request(request)
      rescue StandardError => e
        user_api.mdi.tools.log.error("Error when posting to queue #{queue}, the message will not be reinjected")
        user_api.mdi.tools.print_ruby_exception(e)
      end
    end

  end

end

CC = CloudConnectSDK
