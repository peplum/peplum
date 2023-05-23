module Peplum
class Application
module Services

class SharedHash

  def initialize(*)
    super

    @hash = {}

    @on_set_cb    = {}
    @on_delete_cb = {}
  end

  def get( k )
    @hash[k]
  end

  def set( k, v, broadcast = true )
    return if @hash[k] == v

    @hash[k] = v
    call_on_set( k, v )

    if broadcast
      each_peer do |peer|
        peer.send( name ).set( k, v, false )
      end
    end

    nil
  end

  def delete( k, broadcast = true )
    return if !@hash.include? k

    @hash.delete( k )
    call_on_delete( k )

    if broadcast
      each_peer do |_, peer|
        peer.send( name ).delete( k, false )
      end
    end

    nil
  end

  def on_set( k, &block )
    (@on_set_cb[k] ||= []) << block
  end

  def on_delete( k, &block )
    (@on_delete_cb ||= []) << block
  end

  def to_h
    @hash.dup
  end

  private

  def call_on_set( k, v )
    return if !@on_set_cb[k]

    @on_set_cb[k].each do |cb|
      cb.call v
    end

    nil
  end

  def call_on_delete( k )
    return if !@on_delete_cb[k]

    @on_delete_cb[k].each do |cb|
      cb.call
    end

    nil
  end

  def each_peer( &block )
    Cuboid::Application.application.peers.each( &block )
  end

end

end
end
end
