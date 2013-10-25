require 'unit/test_helper'

describe Pantry::Config do

  it "ensures only one Config object exists" do
    config = Pantry.config
    assert_same config, Pantry.config
  end

  it "has an entry for the server host name" do
    Pantry.config.server_host = "127.0.0.1"
    assert_equal "127.0.0.1", Pantry.config.server_host
  end

  it "has an entry for the pub / sub port" do
    Pantry.config.pub_sub_port = 100
    assert_equal 100, Pantry.config.pub_sub_port
  end

  it "has an entry for the client-info receive port" do
    Pantry.config.receive_port = 7788
    assert_equal 7788, Pantry.config.receive_port
  end

end
