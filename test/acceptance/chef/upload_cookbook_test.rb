require 'acceptance/test_helper'

describe "Uploading cookbooks to the server" do

  it "finds the current cookbook and uploads it" do
    set_up_environment(pub_sub_port: 11000, receive_port: 11001)
    filter = Pantry::Communication::ClientFilter.new

    cli = Pantry::CLI.new(identity: "cli1")
    cli.run

    cli.request(filter, "chef:upload:cookbook", File.expand_path("../../../fixtures/cookbooks/mini", __FILE__))

    sleep 1

    assert File.exists?(File.join(Pantry.config.data_dir, "chef", "cookbooks", "mini", "1.0.0.tgz")),
      "The mini cookbook was not uploaded to the server properly"
  end

#  it "allows forcing a cookbook version up if the version already exists on the server"
#
#  it "reports any upload errors"

end
