require 'unit/test_helper'

describe Pantry::Communication::ReceiveSocket do

  before do
    Celluloid.init

    Celluloid::ZMQ::RouterSocket.any_instance.stubs(:bind)
  end

  let(:security) { Pantry::Communication::Security.new_client }

  it "binds and subscribes to the given host and port" do
    Celluloid::ZMQ::RouterSocket.any_instance.expects(:bind).with("tcp://host:4567")

    socket = Pantry::Communication::ReceiveSocket.new("host", 4567, security)
    socket.open
  end

end
