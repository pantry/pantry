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

  it "can be given a set of filters to limit the request to a certain subset of clients" do
    cli = Pantry::CLI.new(
      filter = Pantry::Communication::ClientFilter.new(
        application: "pantry", environment: "test", roles: %w(db app)
      )
    )

    Pantry::Client.any_instance.expects(:send_request).with do |message|
      assert_equal "ListClients", message.type
      assert_equal filter, message.filter
    end

    cli.request("status")
  end

end
