require 'celluloid/zmq'

module Pantry
  module Communication
    Celluloid::ZMQ.init
  end
end
