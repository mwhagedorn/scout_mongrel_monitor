require 'net/http'
require 'uri'
require 'mongrel_port_manager'


#based on url_monitor by Andre Lewis
#http://www.highgroove.com

class MongrelProcessMonitor
   TIMEOUT_LENGTH = 50

  #returns a hash of ports and whether or not its up 
  def process_status(mongrel_config = "/data/honk/shared/config/mongrel_cluster.yml")
     mongrel_ports = MongrelPortManager.new.mongrel_ports(mongrel_config)
      return [] if mongrel_ports.empty? || mongrel_ports.nil?
      response_summary = Hash.new
      mongrel_ports.each do |port|
            response = self.http_response("http://localhost:#{port}/")
            response_summary[port] = self.valid_http_response?(response)
      end
      response_summary
  end



  def valid_http_response?(result)
    [Net::HTTPOK,Net::HTTPFound].include?(result.class)
  end

  # returns the http response (string) from a url
  def http_response(url)
    uri = URI.parse(url)

    response = nil
    retry_url_trailing_slash = true
    retry_url_execution_expired = true
    begin
      Net::HTTP.start(uri.host,uri.port) {|http|
            http.open_timeout = TIMEOUT_LENGTH
            req = Net::HTTP::Get.new(uri.path)     
            response = http.request(req)     
      }
    rescue Exception => e

      # forgot the trailing slash...add and retry
      if e.message == "HTTP request path is empty" and retry_url_trailing_slash
        url += '/'
        uri = URI.parse(url)
        h = Net::HTTP.new(uri.host)
        retry_url_trailing_slash = false
        retry
      elsif e.message =~ /execution expired/ and retry_url_execution_expired
        retry_url_execution_expired = false
        retry
      else
        response = e.to_s
      end
    end

    return response
  end


end
  
p MongrelProcessMonitor.new.process_status

