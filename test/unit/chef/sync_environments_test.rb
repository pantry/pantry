require 'unit/test_helper'

describe Pantry::Chef::SyncEnvironments do

  describe "#perform" do
    fake_fs!

    it "asks Server for all environments, writes them locally" do
      client = stub_everything

      response = Pantry::Message.new
      response << ["staging.rb", %|name "app"\ndescription ""\n|]
      response << ["test.rb",  %|name "db"\ndescription ""\n|]

      client.expects(:send_request).with do |message|
        assert_equal "Chef::DownloadEnvironments", message.type
      end.returns(mock(:value => response))

      command = Pantry::Chef::SyncEnvironments.new
      command.client = client
      command.perform(Pantry::Message.new)

      assert File.exists?(Pantry.root.join("chef", "environments", "staging.rb")),
        "Did not get the staging.rb environment file"
      assert File.exists?(Pantry.root.join("chef", "environments", "test.rb")),
        "Did not get the test.rb environment file"
    end

  end

end

