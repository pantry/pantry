require 'unit/test_helper'
require 'pantry/communication/receive_socket'

describe Pantry::Communication::ReceiveSocket do

  before do
    Celluloid.init

    Celluloid::ZMQ::RouterSocket.any_instance.stubs(:bind)
  end

  it "binds and subscribes to the given host and port" do
    Celluloid::ZMQ::RouterSocket.any_instance.expects(:bind).with("tcp://host:4567")

    socket = Pantry::Communication::ReceiveSocket.new("host", 4567)
    socket.open
  end

end
