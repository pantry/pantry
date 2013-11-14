require 'unit/test_helper'

describe Pantry::Config do

  let(:pantry_config) { Pantry::Config.new }

  it "ensures only one Config object exists via Pantry.config" do
    config = Pantry.config
    assert_same config, Pantry.config
  end

  describe "Communication Configuration" do
    it "has an entry for the server host name" do
      pantry_config.server_host = "127.0.0.1"
      assert_equal "127.0.0.1", pantry_config.server_host
    end

    it "has an entry for the pub / sub port" do
      pantry_config.pub_sub_port = 100
      assert_equal 100, pantry_config.pub_sub_port
    end

    it "has an entry for the client-info receive port" do
      pantry_config.receive_port = 7788
      assert_equal 7788, pantry_config.receive_port
    end

    it "has an entry for client heartbeat interval" do
      assert_equal 300, pantry_config.client_heartbeat_interval
      pantry_config.client_heartbeat_interval = 5
      assert_equal 5, pantry_config.client_heartbeat_interval
    end
  end

  it "can load values from a given YAML file" do
    config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "config.yml")
    pantry_config.load_file(config_file)

    assert_equal "10.0.0.1", pantry_config.server_host
    assert_equal 12345, pantry_config.pub_sub_port
    assert_equal 54321, pantry_config.receive_port
    assert_equal 600, pantry_config.client_heartbeat_interval
  end

  it "does not set values to nil if not in the config" do
    config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "empty.yml")
    pantry_config.load_file(config_file)

    assert_equal "127.0.0.1", pantry_config.server_host
    assert_equal 23001, pantry_config.pub_sub_port
    assert_equal 23002, pantry_config.receive_port
    assert_equal 300, pantry_config.client_heartbeat_interval
  end
end
