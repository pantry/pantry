require 'unit/test_helper'
require 'pantry/communication/subscribe_socket'

describe Pantry::Communication::SubscribeSocket do

  it "takes the port to use for message subscriptions" do
    socket = Pantry::Communication::SubscribeSocket.new("host", 1234)
    assert_equal "host", socket.host
    assert_equal 1234, socket.port
  end

end
