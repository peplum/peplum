require_relative 'my_app'
require_relative 'rest/helpers'

# Boot up our REST QMap server for easy integration.
rest_pid = MyApp.spawn( :rest, daemonize: true )
at_exit { Cuboid::Processes::Manager.kill rest_pid }

# Wait for the REST server to boot up.
while sleep 1
  begin
    request :get
  rescue Errno::ECONNREFUSED
    next
  end

  break
end

# Assign a QMap Agent to the REST service for it to provide us with scanner Instances.
request :put, 'agent/url', MyApp.spawn( :agent, daemonize: true ).url

# Create a new scanner Instance (process) and run a scan with the following options.
request :post, 'instances', {
  velo: {
    objects:     %w(1 2 3 4 5 6 7 8 9 0),
    max_workers: 5
  },
  native: {
    my_option: { 1 => 2, 3 => 4 }
  }
}

# The ID is used to represent that instance and allow us to manage it from here on out.
instance_id = response_data['id']

while sleep( 1 )
  # Continue looping while instance status is 'busy'.
  request :get, "instances/#{instance_id}"
  break if !response_data['busy']
end

puts '*' * 88

# Get the scan report.
request :get, "instances/#{instance_id}/report.json"

# Print out the report.
puts JSON.pretty_generate( JSON.load( response_data['data'] ) )

# Shutdown the Instance.
request :delete, "instances/#{instance_id}"
