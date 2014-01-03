require 'unit/test_helper'

describe Pantry::Communication::FileService do

  let(:file_service) { Pantry::Communication::FileService.new("host", "port") }

  describe "#start_server" do
    it "binds to the host/port when starting on the server" do
      Celluloid::ZMQ::RouterSocket.any_instance.expects(:bind).with("tcp://host:port")

      file_service.start_server
    end
  end

  describe "#start_client" do
    it "connects to the known server when starting on the client" do
      Celluloid::ZMQ::RouterSocket.any_instance.expects(:connect).with("tcp://host:port")

      file_service.start_client
    end
  end

  it "builds receive-file information, setting the current socket's identity" do
    info = file_service.receive_file(100, "checksum")

    assert_not_nil info
    assert_equal file_service.identity, info.receiver_identity
  end

  it "sends a message to a specific identity" do
    message = Pantry::Message.new
    identity = "123abc"

    Celluloid::ZMQ::RouterSocket.any_instance.expects(:write).with do |message|
      assert_equal message[0], "123abc"
    end

    file_service.send_message(identity, message)
  end

end
