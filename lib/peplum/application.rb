require 'cuboid'
require 'json'
require 'peplum'
require 'peplum/core_ext/array'

module Peplum
  class Application < Cuboid::Application
    require 'peplum/application/peers'

    require 'peplum/application/services/shared_hash'
    require 'peplum/application/services/scheduler'

    class Error < Peplum::Error; end

    class <<self
      def inherited( application )
        super

        Cuboid::Application.application = application

        application.validate_options_with :validate_options
        application.serialize_with JSON

        application.instance_service_for :scheduler,   Services::Scheduler
        application.instance_service_for :shared_hash, Services::SharedHash
      end
    end

    attr_reader :peers

    def initialize(*)
      super

      @peers = Peers.new
    end

    def run
      Raktr.global.on_error do |_, e|
        $stderr.puts e
      end

      options = @options.dup
      peplum_options = options.delete( 'peplum' )
      native_options = options.delete( 'native' )

      # We have a master so we're not the scheduler, run the payload.
      if peplum_options['master']
        execute( peplum_options, native_options )

      # We're the scheduler Instance, get to grouping and spawning.
      else
        schedule( peplum_options, native_options )
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

    def execute( peplum_options, native_options )
      master_info = peplum_options.delete( 'master' )

      self.peers.set( peplum_options.delete( 'peers' ) || {} )

      report_data = native_app.run( peplum_options['objects'], native_options )

      master = Processes::Instances.connect( master_info['url'], master_info['token'] )
      master.scheduler.report report_data, Cuboid::Options.rpc.url
    end

    def schedule( peplum_options, native_options )
      max_workers = peplum_options.delete('max_workers')
      objects     = peplum_options.delete('objects')
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

      scheduler = self.scheduler.class
      instance_num.times.each do |i|
        # Get as many workers as necessary/possible.
        break unless scheduler.get_worker
      end

      # We couldn't get the workers we were going for, Grid reached its capacity,
      # re-balance distribution.
      if scheduler.workers.size < groups.size
        groups = native_app.group( objects, scheduler.workers.size )
      end

      peers = Hash[scheduler.workers.values.map { |client| [client.url, client.token] }]

      scheduler.workers.values.each do |worker|
        worker.run(
          peplum: {
            objects: groups.pop,
            peers:   peers,
            master:  {
              url: Cuboid::Options.rpc.url,
              token: Cuboid::Options.datastore.token
            }
          },
          native: native_options
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

      @options = options
      true
    end

  end
end
