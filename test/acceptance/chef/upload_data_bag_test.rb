require 'acceptance/test_helper'
require 'fileutils'

describe "Uploading data bag definitions to the server" do

  it "uploads the given file as a Chef data bag" do
    set_up_environment(ports_start_at: 11500)

    cli = Pantry::CLI.new(
      ["-a", "pantry", "chef:data_bag:upload", fixture_path("data_bags/settings/test.json")],
      identity: "cli1"
    )
    cli.run

    assert File.exists?(Pantry.root.join(
      "applications", "pantry", "chef", "data_bags", "settings", "test.json")),
      "The test settings data bag was not uploaded to the server properly"
  end

  it "can be told the explicit name of the data bag type" do
    set_up_environment(ports_start_at: 11510)

    cli = Pantry::CLI.new(
      ["-a", "pantry", "chef:data_bag:upload", "-t", "users", fixture_path("data_bags/settings/test.json")],
      identity: "cli1"
    )
    cli.run

    assert File.exists?(Pantry.root.join(
      "applications", "pantry", "chef", "data_bags", "users", "test.json")),
      "The test settings data bag was not uploaded to the server properly"
  end

end

