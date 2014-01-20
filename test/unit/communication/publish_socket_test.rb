require 'unit/test_helper'

describe Pantry::Communication::PublishSocket do

  before do
    Celluloid.boot
  end

  let(:security) { Pantry::Communication::Security.new_client }

  it "opens a ZMQ PubSocket, bound to host / port" do
    Celluloid::ZMQ::PubSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::PubSocket.any_instance.expects(:bind).with("tcp://host:1234")

    socket = Pantry::Communication::PublishSocket.new("host", 1234, security)
    socket.open
  end

end
