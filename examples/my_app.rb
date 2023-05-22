require 'pp'
require 'velo'

class MyApp < Velo::Application

  # 100MB RAM should be more than enough for native and Velo.
  provision_memory 100 * 1024 * 1024

  # 100MB disk space should be more than enough.
  provision_disk   100 * 1024 * 1024

  module Native

    def run( objects, options = nil )
      pp [objects, options]
    end

    def group( objects, chunks )
      objects.chunk chunks
    end

    def merge( data )
      data
    end

    extend self
  end

  def native_app
    Native
  end

end
