require 'pp'
require 'peplum'

class MyApp < Peplum::Application
  require_relative 'my_app/my_service'

  # 100MB RAM should be more than enough for native and Peplum.
  provision_memory 100 * 1024 * 1024

  # 100MB disk space should be more than enough.
  provision_disk   100 * 1024 * 1024

  # Add custom service to be accessible over the network.
  instance_service_for :my_service, MyService

  module Native

    # Run payload against `objects`.
    def run( objects, options = nil )
      # Signal that we started work or something to our peers...
      MyApp.shared_hash.set( Process.pid, options )

      # Access peer's services.
      MyApp.peers.each do |peer|
        p peer.my_service.foo
        pp peer.my_service.shared_hash_to_hash
      end

      pp [objects, options]
    end

    # Distribute `objects` into `chunks` amount of groups, one for each worker.
    def group( objects, chunks )
      objects.chunk chunks
    end

    # Merge result `data` for reporting.
    def merge( data )
      data
    end

    extend self
  end

  def native_app
    Native
  end

end
