require 'unit/test_helper'

describe Pantry::Chef::SyncRoles do

  it "has a custom type" do
    assert_equal "Chef::SyncRoles", Pantry::Chef::SyncRoles.command_type
  end

  describe "#perform" do
    fake_fs!

    it "asks Server for all roles, writes them locally" do
      client = stub_everything

      response = Pantry::Message.new
      response << ["app.rb", %|name "app"\ndescription ""\n|]
      response << ["db.rb",  %|name "db"\ndescription ""\n|]

      client.expects(:send_request).with do |message|
        assert_equal "Chef::DownloadRoles", message.type
      end.returns(mock(:value => response))

      command = Pantry::Chef::SyncRoles.new
      command.client = client
      command.perform(Pantry::Message.new)

      assert File.exists?(Pantry.root.join("chef", "roles", "app.rb")),
        "Did not get the app.rb role file"
      assert File.exists?(Pantry.root.join("chef", "roles", "db.rb")),
        "Did not get the db.rb role file"
    end

  end

end

