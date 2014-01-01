require 'acceptance/test_helper'
require 'fileutils'

describe "Uploading cookbooks to the server" do

  it "finds the current cookbook and uploads it" do
    set_up_environment(ports_start_at: 11000)

    cli = Pantry::CLI.new(
      ["chef:cookbook:upload", File.expand_path("../../../fixtures/cookbooks/mini", __FILE__)],
      identity: "cli1"
    )
    cli.run

    sleep 1

    assert File.exists?(Pantry.root.join("chef", "cookbooks", "mini", "1.0.0.tgz")),
      "The mini cookbook was not uploaded to the server properly"
  end

  it "allows forcing a cookbook version up if the version already exists on the server" do
    set_up_environment(ports_start_at: 11010)

    chef_dir = Pantry.root.join("chef", "cookbooks", "mini")
    FileUtils.mkdir_p chef_dir
    system "touch #{File.join(chef_dir, "1.0.0.tgz")}"

    cli = Pantry::CLI.new(
      ["chef:cookbook:upload", "-f", File.expand_path("../../../fixtures/cookbooks/mini", __FILE__)],
      identity: "cli1"
    )
    cli.run

    sleep 1

    assert File.size(Pantry.root.join("chef", "cookbooks", "mini", "1.0.0.tgz")) > 0,
      "The mini cookbook was not properly forced into place"
  end

  it "reports any upload errors"

end
