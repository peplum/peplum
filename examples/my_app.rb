require 'pp'
require 'peplum'

class MyApp < Peplum::Application

  # 100MB RAM should be more than enough for native and Peplum.
  provision_memory 100 * 1024 * 1024

  # 100MB disk space should be more than enough.
  provision_disk   100 * 1024 * 1024

  module Native

    # Run payload against `objects`.
    def run( objects, options = nil )
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
