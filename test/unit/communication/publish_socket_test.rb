require 'unit/test_helper'
require 'pantry/communication/publish_socket'

describe Pantry::Communication::PublishSocket do

  it "takes the port to use for message publishing" do
    socket = Pantry::Communication::PublishSocket.new("host", 1234)
    assert_equal "host", socket.host
    assert_equal 1234, socket.port
  end

end
