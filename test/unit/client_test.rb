require 'unit/test_helper'
require 'pantry/client'

describe Pantry::Client do
  it "takes a server config on initialization" do
    client = Pantry::Client.new server_host: "localhost", subscribe_port: 10101

    assert_equal 10101, client.subscribe_port
    assert_equal "localhost", client.server_host
  end
end
