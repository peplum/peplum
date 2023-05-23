module Peplum
class Application
module Services

class SharedHash

  def initialize
    @hash         = {}
    @sync_counter = 0
  end

  def get( k )
    @hash[k]
  end

  def set( k, v, broadcast = true, &block )
    if @hash[k] == v
      block.call if block_given?
      return
    end

    @hash[k] = v

    if broadcast
      each_peer do |peer|
        @sync_counter += 1
        peer.shared_hash.set( k, v, false ) { @sync_counter -= 1 }
      end
    end

    block.call if block_given?
    nil
  end

  def delete( k, broadcast = true )
    if !@hash.include? k
      block.call if block_given?
      return
    end

    @hash.delete( k )

    if broadcast
      each_peer do |_, peer|
        @sync_counter += 1
        peer.shared_hash.delete( k, false ) { @sync_counter -= 1 }
      end
    end

    block.call if block_given?
    nil
  end

  def to_h
    @hash.dup
  end

  def sync
    sleep 0.1 while @sync_counter != 0
  end

  private

  def each_peer( &block )
    Cuboid::Application.application.peers.each( &block )
  end

end

end
end
end
