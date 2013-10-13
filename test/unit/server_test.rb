require 'unit/test_helper'
require 'pantry/server'

describe Pantry::Server do
  it "takes a server config on initialization" do
    server = Pantry::Server.new publish_port: 10101
    assert_equal 10101, server.publish_port
  end
end
