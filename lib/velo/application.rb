require 'cuboid'
require 'json'
require 'velo'
require 'velo/core_ext/array'

module Velo
  class Application < Cuboid::Application
    require 'velo/application/scheduler'

    class Error < Velo::Error; end

    class <<self
      def inherited( application )
        super

        Cuboid::Application.application = application

        application.validate_options_with :validate_options
        application.serialize_with JSON

        application.instance_service_for :scheduler, Scheduler
      end
    end

    def run
      options = @options.dup
      velo_options   = options.delete( 'velo' )
      native_options = options.delete( 'native' )

      # We have a master so we're not the scheduler, run the payload.
      if (master_info = velo_options.delete( 'master' ))
        report_data = native_app.run( velo_options['objects'], native_options )

        master = Processes::Instances.connect( master_info['url'], master_info['token'] )
        master.scheduler.report report_data, Cuboid::Options.rpc.url

      # We're the scheduler Instance.
      else
        max_workers = velo_options.delete('max_workers')
        objects     = velo_options.delete('objects')
        groups      = native_app.group( objects, max_workers )

        # Workload turned out to be less than our maximum allowed instances.
        # Don't spawn the max if we don't have to.
        if groups.size < max_workers
          instance_num = groups.size

        # Workload distribution turned out as expected.
        elsif groups.size == max_workers
          instance_num = max_workers

        # What the hell did just happen1?
        else
          fail Error, 'Workload distribution error, uneven grouping!'
        end

        instance_num.times.each do |i|
          # Get as many workers as necessary/possible.
          break unless self.scheduler.get_worker
        end

        # We couldn't get the workers we were going for, Grid reached its capacity,
        # re-balance distribution.
        if self.scheduler.workers.size < groups.size
          groups = native_app.group( objects, self.scheduler.workers.size )
        end

        self.scheduler.workers.values.each do |worker|
          worker.run(
            velo: {
              objects: groups.pop,
              master:  {
                url: Cuboid::Options.rpc.url,
                token: Cuboid::Options.datastore.token
              }
            },
            native: native_options
          )
        end

        self.scheduler.wait
      end
    end

    # Implements:
    #   * `.run` -- Worker; executes its payload against `objects`.
    #   * `.group` -- Splits given `objects` into groups for each worker.
    #   * `.merge` -- Merges results from multiple workers.
    #
    # That's all we need to turn any application into a super version of itself.
    #
    # @abstract
    def native_app
      fail Error, 'Missing native app!'
    end

    def report( data )
      super native_app.merge( data )
    end

    private

    def validate_options( options )
      if !Cuboid::Options.agent.url
        fail Error, 'Missing Agent!'
      end

      velo_options = options['velo']

      if !velo_options.include? 'objects'
        fail Error, 'Options: Missing :objects'
      end

      if !velo_options['master'] && !velo_options.include?( 'max_workers' )
        fail Error, 'Options: Missing :max_workers'
      end

      @options = options
      true
    end

  end
end
