module Peplum
class Application

module Worker

  # @return   [Cuboid::RPC::Server::Instance::Peers]
  attr_reader :peers

  # @return   [Cuboid::RPC::Client::Instance, NilClass]
  attr_reader :scheduler

  def peers
    @peers ||= Cuboid::RPC::Server::Instance::Peers.new
  end

end

end
end
