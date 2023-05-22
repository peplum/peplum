require 'json'
require 'tmpdir'
require 'net/http'

def response
  if @last_response['Content-Type'].include? 'json'
    data = JSON.load( @last_response.body )
  else
    data = @last_response.body
  end
  {
    code: @last_response.code,
    data: data
  }
end

def response_data
  response[:data]
end

def request( method, resource = nil, parameters = nil )
  uri = URI( "http://127.0.0.1:7331/#{resource}" )

  Net::HTTP.start( uri.host, uri.port) do |http|
    case method
    when :get
      uri.query = URI.encode_www_form( parameters ) if parameters
      request = Net::HTTP::Get.new( uri )

    when :post
      request = Net::HTTP::Post.new( uri )
      request.body = parameters.to_json

    when :delete
      request = Net::HTTP::Delete.new( uri )

    when :put
      request = Net::HTTP::Put.new( uri )
      request.body = parameters.to_json
    end

    @last_response = http.request( request )
  end
end
