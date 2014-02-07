require 'acceptance/test_helper'

describe "Running Chef on a Client" do

  mock_ui!

  it "configures chef, syncs cookbooks from server to the client and runs chef solo" do
    set_up_environment(ports_start_at: 12000)

    # Make sure cookbook is uploaded to the server
    Pantry::CLI.new(
      ["chef:cookbook:upload", fixture_path("cookbooks/mini")],
      identity: "cli1"
    ).run

    # Add a role definition
    Pantry::CLI.new(
      ["-a", "pantry", "chef:role:upload", fixture_path("roles/app1.rb")],
      identity: "cli2"
    ).run

    # Add an environment definition
    Pantry::CLI.new(
      ["-a", "pantry", "chef:environment:upload", fixture_path("environments/test.rb")],
      identity: "cli3"
    ).run

    # Add a data bag
    Pantry::CLI.new(
      ["-a", "pantry", "chef:data_bag:upload", fixture_path("data_bags/settings/test.json")],
      identity: "cli4"
    ).run

    # Run chef to sync the cookbooks to the client
    Pantry::CLI.new(
      ["-a", "pantry", "-e", "test", "-r", "app1", "chef:run"],
      identity: "cli-runner"
    ).run

    # Configure chef
    assert File.exists?(Pantry.root.join("etc", "chef", "solo.rb")),
      "Did not write out the solo file"
    assert File.exists?(Pantry.root.join("etc", "chef", "node.json")),
      "Did not write out the node file"

    # Sync roles and environments
    assert File.exists?(Pantry.root.join("chef", "roles", "app1.rb")),
      "Did not sync the role files"
    assert File.exists?(Pantry.root.join("chef", "environments", "test.rb")),
      "Did not sync the environment files"

    # Sync Cookbooks
    assert File.exists?(Pantry.root.join("chef", "cookbooks", "mini", "metadata.rb")),
      "Did not receive the mini cookbook from the server"
    assert File.directory?(Pantry.root.join("chef", "cookbooks", "mini", "recipes")),
      "Did not receive the mini cookbook from the server"

    # Sync Data Bags
    assert File.exists?(Pantry.root.join("chef", "data_bags", "settings", "test.json")),
      "Did not receive the test settings data bag from the server"

    # Run chef-solo
    assert File.exists?(Pantry.root.join("chef", "cache", "chef-client-running.pid")),
      "Did not run chef-solo"

    assert_match /Chef Run complete in/, stdout
  end

end
