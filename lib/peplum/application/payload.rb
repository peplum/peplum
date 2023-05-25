module Peplum
class Application
module Payload

  class Error < Error
    class ImplementationMissing < Error
    end
  end

  # Run payload against `objects` based on given `options`
  #
  # @param  [Array] objects Objects that this worker should process.
  # @param  [Hash, NilClass]  options Worker options.
  # @abstract
  def run( objects, options )
    fail Error::ImplementationMissing, 'Missing implentation.'
  end

  # Distribute `objects` into `groups_of` amount of groups, one for each worker.
  #
  # @param  [Array] objects All objects that need to be processed.
  # @param  [Integer] groups_of  Amount of object groups that should be generated.
  #
  # @return [Array<Array<Object>>]  `objects` split in `chunks` amount of groups.
  def split( objects, groups_of )
    objects.chunk groups_of
  end

  # Merge result `data` for reporting.
  #
  # @param  [Array] data  Report data from workers.
  # @abstract
  def merge( data )
    fail Error::ImplementationMissing, 'Missing implentation.'
  end

end
end
end
