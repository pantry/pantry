require 'unit/test_helper'
require 'pantry/communication/subscribe_socket'

describe Pantry::Communication::SubscribeSocket do

  before do
    Celluloid.init

    Celluloid::ZMQ::SubSocket.any_instance.stubs(:linger=)
    Celluloid::ZMQ::SubSocket.any_instance.stubs(:connect)
    Celluloid::ZMQ::SubSocket.any_instance.stubs(:subscribe)
  end

  it "binds and subscribes to the given host and port" do
    Celluloid::ZMQ::SubSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::SubSocket.any_instance.expects(:connect).with("tcp://host:1235")
    Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("")

    socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
    socket.open
  end

  describe "subscription filtering" do
    it "subscribes to the stream according to filter options given" do
      socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
      socket.filter_on(Pantry::Communication::ClientFilter.new(application: "pantry"))

      Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("pantry")

      socket.open
    end

    it "subscribes to multiple streams to support nested scoping" do
      socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
      socket.filter_on(Pantry::Communication::ClientFilter.new(
        application: "pantry", environment: "test"))

      Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("pantry")
      Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("pantry.test")

      socket.open
    end
  end

end
