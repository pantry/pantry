require 'acceptance/test_helper'
require 'fileutils'

describe "Uploading environment definitions to the server" do

  it "uploads the given file as a Chef environment" do
    set_up_environment(ports_start_at: 14000)

    cli = Pantry::CLI.new(
      ["chef:environment:upload", fixture_path("environments/test.rb")],
      identity: "cli1"
    )
    cli.run

    assert File.exists?(Pantry.root.join("chef", "environments", "test.rb")),
      "The test environment was not uploaded to the server properly"
  end

end

