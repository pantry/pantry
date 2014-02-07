require 'unit/test_helper'

describe Pantry::Chef::SyncCookbooks do

  describe "#perform" do

    it "requests to the server a list of cookbooks it should have" do
      client = stub_everything
      client.expects(:send_request).with do |message|
        assert_equal "Chef::ListCookbooks", message.type
      end.returns(mock(:value => Pantry::Message.new))

      command = Pantry::Chef::SyncCookbooks.new
      command.client = client
      command.perform(Pantry::Message.new)
    end

    it "fires off receivers for each cookbook in the list and waits for downloads to finish" do
      client = stub_everything
      message = Pantry::Message.new
      message << ["cookbook1", 0, "checksum1"]

      client.stubs(:send_request).returns(stub(:value => message)).times(2)

      client.expects(:receive_file).with(0, "checksum1").returns(
        receive_info = Pantry::Communication::FileService::ReceivingFile.new(0, "checksum1", 1, 1)
      )

      receive_info.expects(:wait_for_finish)

      command = Pantry::Chef::SyncCookbooks.new
      command.client = client
      command.perform(Pantry::Message.new)
    end

    it "deletes cookbooks stored locally not in the list (?)"

  end

end
