require 'unit/test_helper'
require 'pantry/communication/send_socket'
require 'pantry/communication/message'

describe Pantry::Communication::SendSocket do

  before do
    Celluloid.boot
  end

  it "opens a ZMQ DealerSocket, bound to host / port" do
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:connect).with("tcp://host:1234")

    socket = Pantry::Communication::SendSocket.new("host", 1234)
    socket.open
  end

end
