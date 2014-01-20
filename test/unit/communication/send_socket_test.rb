require 'unit/test_helper'

describe Pantry::Communication::SendSocket do

  before do
    Celluloid.boot
  end

  let(:security) { Pantry::Communication::Security.new_client }

  it "opens a ZMQ DealerSocket, bound to host / port" do
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:connect).with("tcp://host:1234")

    socket = Pantry::Communication::SendSocket.new("host", 1234, security)
    socket.open
  end

end
