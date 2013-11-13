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

  it "has an entry for client heartbeat interval" do
    assert_equal 300, Pantry.config.client_heartbeat_interval
    Pantry.config.client_heartbeat_interval = 5
    assert_equal 5, Pantry.config.client_heartbeat_interval
  end

  it "can load values from a given YAML file" do
    config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "config.yml")
    Pantry.config.load_file(config_file)

    assert_equal "10.0.0.1", Pantry.config.server_host
    assert_equal 12345, Pantry.config.pub_sub_port
    assert_equal 54321, Pantry.config.receive_port
    assert_equal 300, Pantry.config.client_heartbeat_interval
  end
end
