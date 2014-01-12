require 'unit/test_helper'

describe Pantry::Chef::SyncRoles do

  it "reads from the server directory for chef" do
    cmd = Pantry::Chef::SyncRoles.new
    cmd.client = Pantry::ClientInfo.new(application: "pantry")

    dir = cmd.server_directory(Pathname.new(""))
    assert_equal "applications/pantry/chef/roles", dir.to_s
  end

  it "writes to the client's local chef dir" do
    cmd = Pantry::Chef::SyncRoles.new

    dir = cmd.client_directory(Pathname.new(""))
    assert_equal "chef/roles", dir.to_s
  end

end

