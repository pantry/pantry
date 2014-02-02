require 'unit/test_helper'

describe Pantry::Chef::SyncDataBags do

  it "reads from the server directory for chef" do
    cmd = Pantry::Chef::SyncDataBags.new
    cmd.client = Pantry::ClientInfo.new(application: "pantry")

    dir = cmd.server_directory(Pathname.new(""))
    assert_equal "applications/pantry/chef/data_bags", dir.to_s
  end

  it "writes to the client's local chef dir" do
    cmd = Pantry::Chef::SyncDataBags.new

    dir = cmd.client_directory(Pathname.new(""))
    assert_equal "chef/data_bags", dir.to_s
  end

end

