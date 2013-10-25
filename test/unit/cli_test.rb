require 'unit/test_helper'
require 'pantry/cli'
require 'pantry/communication/message'

describe Pantry::CLI do

  before do
    Pantry::Client.any_instance.stubs(:run)
  end

  it "builds a message from a command request and sends it to the server" do
    cli = Pantry::CLI.new

    Pantry::Client.any_instance.expects(:send_request).with do |message|
      assert_equal "ListClients", message.type
    end

    cli.request("status")
  end

end
