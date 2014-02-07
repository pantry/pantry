require 'acceptance/test_helper'
require 'fileutils'

describe "Uploading cookbooks to the server" do

  mock_ui!

  it "finds the current cookbook and uploads it" do
    set_up_environment(ports_start_at: 11000)

    Pantry::CLI.new(
      ["chef:cookbook:upload", fixture_path("cookbooks/mini")],
      identity: "cli1"
    ).run

    assert File.exists?(Pantry.root.join("chef", "cookbooks", "mini", "metadata.rb")),
      "The mini cookbook was not uploaded to the server properly"
    assert File.exists?(Pantry.root.join("chef", "cookbook-cache", "mini.tgz")),
      "The uploaded tar ball was not saved to the upload cache"
  end

  it "reports any upload errors"

end
