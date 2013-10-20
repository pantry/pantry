require 'unit/test_helper'
require 'pantry/communication/publish_socket'
require 'pantry/communication/message'

describe Pantry::Communication::PublishSocket do

  before do
    Celluloid.boot
  end

  it "opens a ZMQ PubSocket, bound to host / port" do
    Celluloid::ZMQ::PubSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::PubSocket.any_instance.expects(:bind).with("tcp://host:1234")

    socket = Pantry::Communication::PublishSocket.new("host", 1234)
    socket.open
  end

end
