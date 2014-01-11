require 'acceptance/test_helper'
require 'fileutils'

describe "Uploading role definitions to the server" do

  it "uploads the given file as a Chef role" do
    set_up_environment(ports_start_at: 13000)

    cli = Pantry::CLI.new(
      ["chef:role:upload", fixture_path("roles/staging.rb")],
      identity: "cli1"
    )
    cli.run

    assert File.exists?(Pantry.root.join("chef", "roles", "staging.rb")),
      "The staging role was not uploaded to the server properly"
  end

end

