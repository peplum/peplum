require 'peplum/core_ext/array'

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
    fail Error::ImplementationMissing, 'Missing implementation.'
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
  # By default provides a generic implementation that merges the values of `Hash`es and `Array`s.
  # If `String`s or `Numeric`s are contained, the Array is returned as is.
  #
  # @param  [Array] data  Report data from workers.
  # @return [Object]  Merged results.
  #
  # @raise  [Error::ImplementationMissing]  When the data cannot be handled.
  def merge( data )
    case data.first
    when Hash
        f = data.pop
        data.each do |d|

          if !f.is_a? Hash
            fail Error::ImplementationMissing, 'Missing implementation: Item not a Hash!'
          end

          f.merge! d
        end
        f

    when Array
      data.flatten

    when String, Numeric
      data

    else
      fail Error::ImplementationMissing, 'Missing implementation.'
    end
  end

end
end
end
