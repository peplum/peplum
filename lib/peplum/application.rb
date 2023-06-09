require 'cuboid'
require 'json'
require 'peplum'

module Peplum
  class Application < Cuboid::Application
    require 'peplum/application/worker'
    require 'peplum/application/payload'

    require 'peplum/application/services/shared_hash'
    require 'peplum/application/services/scheduler'

    class Error < Peplum::Error
      class PayloadMissing < Error
      end
    end

    # Hijack Cuboid to set ourselves up.
    class <<self
      def inherited( application )
        super

        # Don't trust Cuboid's auto-detection for this, make sure the inheriting class is the Cuboid application.
        Cuboid::Application.application = application

        application.validate_options_with :validate_options

        application.instance_service_for :scheduler,   Services::Scheduler

        # Shared, in-memory key-value store for the workers, the scheduler will not be participate.
        application.instance_service_for :shared_hash, Services::SharedHash
      end
    end

    def run
      options = @options.dup

      # System options.
      peplum_options = options.delete( 'peplum' )

      # Payload options.
      payload_options = options.delete( 'payload' )

      # We have a master so we're a worker, run the payload.
      if peplum_options['master']
        work( peplum_options, payload_options )

      # We're the scheduler Instance, get to grouping objects and spawning workers.
      else
        schedule( peplum_options, payload_options )
      end
    end

    # @return [#run, #split, #merge]
    #
    #   * `#run` -- Worker; executes its payload against `objects`.
    #   * `#split` -- Scheduler; splits given `objects` into groups for each worker.
    #   * `#merge` -- Scheduler; merges results from multiple workers.
    #
    #   That's all we need to turn any application into a super version of itself.
    #
    # @abstract
   def payload
      fail Error::PayloadMissing, 'Missing #payload implementation!'
    end

    # Overload {Cuboid#report} and delegate to the {Payload.merge} prior passing it on to {Cuboid}.
    # @private
    def report( data )
      super payload.merge( data )
    end

    private

    def work( peplum_options, payload_options )
      # We're now a worker class!
      self.class.include Worker

      master_info = peplum_options.delete( 'master' )
      @master = Processes::Instances.connect( master_info['url'], master_info['token'] )

      # Configure us to know the rest of our worker peers.
      # Required for the SharedHash service.
      self.peers.set( peplum_options.delete( 'peers' ) || {} )

      # Deliver the payload.
      report_data = payload.run( peplum_options['objects'], payload_options )

      # Signal that we're done by passing our report to the scheduler.
      @master.scheduler.report report_data, Cuboid::Options.rpc.url
    end

    def schedule( peplum_options, payload_options )
      max_workers = peplum_options.delete('max_workers')
      objects     = peplum_options.delete('objects')
      groups      = payload.split( objects, max_workers )

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

      scheduler = self.scheduler.class
      instance_num.times.each do |i|
        # Get as many workers as necessary/possible.
        break unless scheduler.get_worker
      end

      # We couldn't get the workers we were going for, Grid reached its capacity,
      # re-balance distribution.
      if scheduler.workers.size < groups.size
        groups = payload.group( objects, scheduler.workers.size )
      end

      peers = Hash[scheduler.workers.values.map { |client| [client.url, client.token] }]

      scheduler.workers.values.each do |worker|
        worker.run(
          peplum: {
            objects: groups.pop,
            peers:   peers,
            master:  {
              url:   Cuboid::Options.rpc.url,
              token: Cuboid::Options.datastore.token
            }
          },
          payload: payload_options
        )
      end

      scheduler.wait
    end

    def validate_options( options )
      if !Cuboid::Options.agent.url
        fail Error, 'Missing Agent!'
      end

      peplum_options = options['peplum']

      if !peplum_options.include? 'objects'
        fail Error, 'Options: Missing :objects'
      end

      if !peplum_options['master'] && !peplum_options.include?( 'max_workers' )
        fail Error, 'Options: Missing :max_workers'
      end

      validate_payload

      @options = options
      true
    end

    def validate_payload
      p = self.payload

      %w(run merge split).each do |m|
        next if p.respond_to? m
        fail Payload::Error::ImplementationMissing, "#{payload} missing implementation for: ##{m}"
      end
    end

  end
end
