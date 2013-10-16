require 'unit/test_helper'
require 'pantry/server'

describe Pantry::Server do

  before do
    Celluloid.init
  end

  it "opens a publish socket for communication, closing it on shutdown" do
    Pantry::Communication::PublishSocket.any_instance.expects(:open)
    Pantry::Communication::PublishSocket.any_instance.expects(:close)

    server = Pantry::Server.new
    server.run
    server.shutdown
  end

  it "uses the publish socket to send messages to clients" do
    Pantry::Communication::PublishSocket.any_instance.stubs(:open)
    server = Pantry::Server.new
    server.run

    Pantry::Communication::PublishSocket.any_instance.stubs(:open)
    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with("message")

    server.publish_to_clients("message")
  end

end
