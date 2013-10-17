require 'unit/test_helper'
require 'pantry/server'

describe Pantry::Server do

  before do
    Celluloid.init
    Pantry::Communication::PublishSocket.any_instance.stubs(:open)
  end

  it "opens a publish socket for communication, closing it on shutdown" do
    Pantry::Communication::PublishSocket.any_instance.expects(:open)
    Pantry::Communication::PublishSocket.any_instance.expects(:close)

    server = Pantry::Server.new
    server.run
    server.shutdown
  end

  it "uses the publish socket to send messages to clients" do
    server = Pantry::Server.new
    server.run

    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with("message", nil)

    server.publish_to_clients("message")
  end

  it "passes down a given MessageFilter to the socket" do
    server = Pantry::Server.new
    server.run

    filter = Pantry::Communication::MessageFilter.new
    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with("message", filter)

    server.publish_to_clients("message", filter)
  end

end
