require_relative 'my_app'

# Spawn a QMap Agent as a daemon.
myapp_agent = MyApp.spawn( :agent, daemonize: true )

# Spawn and connect to an Instance.
myapp = MyApp.connect( myapp_agent.spawn )
# Don't forget this!
at_exit { myapp.shutdown }

myapp.run(
  peplum: {
    objects:     %w(1 2 3 4 5 6 7 8 9 0),
    max_workers: 5
  },
  native: {
    my_option: { 1 => 2, 3 => 4 }
  }
)

# Waiting to complete.
sleep 1 while myapp.running?

# Hooray!
puts JSON.pretty_generate( myapp.generate_report.data )
