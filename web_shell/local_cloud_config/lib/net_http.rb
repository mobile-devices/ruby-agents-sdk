#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'net/http'

def http_get(address)
  url = URI.parse(address)
  path = url.path
  path += "?" + url.query if url.query
  req = Net::HTTP::Get.new(path)
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.request(req)
  }
  res.body
end

def http_post(address, parameters_str)
  `curl -i -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '#{parameters_str.to_json}' http://localhost:5001/remote_call`
end