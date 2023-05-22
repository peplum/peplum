module Peplum
class Application

class SharedHash

  def initialize
    @hash = {}
  end

  def get( k )
    @hash[k]
  end

  def set( k, v, broadcast = true )
    return if @hash[k] == v

    @hash[k] = v

    if broadcast
      each_peer do |_, peer|
        peer.shared_hash.set( k, v, false )
      end
    end

    nil
  end

  def delete( k, broadcast = true )
    return if !@hash.include? k

    @hash.delete( k )

    if broadcast
      each_peer do |_, peer|
        peer.shared_hash.delete( k, false )
      end
    end

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
