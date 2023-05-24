module Peplum
class Application
module Services

class SharedHash

  CONCURRENCY = 20

  def initialize(*)
    super

    @hash = {}

    @on_set_cb    = {}
    @on_delete_cb = {}
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
    call_on_set( k, v )

    if broadcast
      each_peer do |peer, iterator|
        peer.send( name ).set( k, v, false ) { iterator.next }
      end
    end

    block.call if block_given?
    nil
  end

  def delete( k, broadcast = true, &block )
    if !@hash.include? k
      block.call if block_given?
      return
    end

    @hash.delete( k )
    call_on_delete( k )

    if broadcast
      each_peer do |peer, iterator|
        peer.send( name ).delete( k, false ) { iterator.next }
      end
    end

    block.call if block_given?
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
    each  = proc do |client, iterator|
      block.call client, iterator
    end
    Raktr.global.create_iterator( Cuboid::Application.application.peers.to_a, CONCURRENCY ).each( each )
  end

end

end
end
end
