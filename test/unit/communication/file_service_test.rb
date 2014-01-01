require 'unit/test_helper'

describe Pantry::Communication::FileService do

  let(:file_service) { Pantry::Communication::FileService.new("host", "port") }

  describe "#start_server" do
    it "binds to the host/port when starting on the server" do
      Celluloid::ZMQ::DealerSocket.any_instance.expects(:bind).with("tcp://host:port")

      file_service.start_server
    end
  end

  describe "#start_client" do
    it "connects to the known server when starting on the client" do
      Celluloid::ZMQ::DealerSocket.any_instance.expects(:connect).with("tcp://host:port")

      file_service.start_client
    end
  end

end
