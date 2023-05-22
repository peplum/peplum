module Peplum
class Application
module Services

class SharedHash

  def initialize
    @hash = {}
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
        peer.shared_hash.set( k, v, false ) {}
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
        peer.shared_hash.delete( k, false ) {}
      end
    end

    block.call if block_given?
    nil
  end

  def to_h
    @hash.dup
  end

  private

  def each_peer( &block )
    Cuboid::Application.application.peers.each( &block )
  end

end

end
end
end
