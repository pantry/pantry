require 'acceptance/test_helper'

describe "Running Chef on a Client" do

  it "configures chef, syncs cookbooks from server to the client and runs chef solo" do
    set_up_environment(ports_start_at: 12000)

    # Make sure cookbook is uploaded to the server
    Pantry::CLI.new(
      ["chef:cookbook:upload", fixture_path("cookbooks/mini")],
      identity: "cli1"
    ).run

    # Run chef to sync the cookbooks to the client
    Pantry::CLI.new(
      ["-a", "pantry", "-e", "test", "-r", "app1", "chef:run"],
      identity: "cli2"
    ).run

    # Configure chef
    assert File.exists?(Pantry.root.join("etc", "chef", "solo.rb")),
      "Did not write out the solo file"

    # Sync Cookbooks
    assert File.exists?(Pantry.root.join("chef", "cookbooks", "mini", "metadata.rb")),
      "Did not receive the mini cookbook from the server"
    assert File.directory?(Pantry.root.join("chef", "cookbooks", "mini", "recipes")),
      "Did not receive the mini cookbook from the server"

    # Run chef-solo
    assert File.exists?(Pantry.root.join("chef", "cache", "chef-client-running.pid")),
      "Did not run chef-solo"
  end

end
