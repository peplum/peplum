module Peplum
class Application

class Peers

  def initialize
    @peers = {}
  end

  def set( peer_info )
    peer_info.each do |url, token|
      next if url == self.self_url
      @peers[url] = Peplum::Application.connect( url: url, token: token )
    end

    nil
  end

  def each( &block )
    @peers.each do |url, client|
      block.call url, client
    end
  end

  def self_url
    Cuboid::Options.rpc.url
  end

end

end
end
