require 'unit/test_helper'

describe Pantry::Config do

  let(:pantry_config) { Pantry::Config.new }

  it "ensures only one Config object exists via Pantry.config" do
    config = Pantry.config
    assert_same config, Pantry.config
  end

  describe "Global Configs" do
    it "has an entry for logging destination" do
      pantry_config.log_to = "stdout"
      assert_equal "stdout", pantry_config.log_to
    end

    it "has an entry for the log level" do
      assert_equal "info", pantry_config.log_level

      pantry_config.log_level = "warn"
      assert_equal "warn", pantry_config.log_level
    end

    it "can load values from a given YAML file" do
      config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "config.yml")
      pantry_config.load_file(config_file)

      assert_equal "/var/log/pantry.log", pantry_config.log_to
      assert_equal "warn", pantry_config.log_level
    end

    it "does not set values to nil if not in the config" do
      config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "empty.yml")
      pantry_config.load_file(config_file)

      assert_equal "info", pantry_config.log_level
    end
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

    it "can load values from a given YAML file" do
      config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "config.yml")
      pantry_config.load_file(config_file)

      assert_equal "10.0.0.1", pantry_config.server_host
      assert_equal 12345, pantry_config.pub_sub_port
      assert_equal 54321, pantry_config.receive_port
    end

    it "does not set values to nil if not in the config" do
      config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "empty.yml")
      pantry_config.load_file(config_file)

      assert_equal "127.0.0.1", pantry_config.server_host
      assert_equal 23001, pantry_config.pub_sub_port
      assert_equal 23002, pantry_config.receive_port
    end
  end

  describe "Client-side Configuration" do
    it "has an entry for client heartbeat interval" do
      assert_equal 300, pantry_config.client_heartbeat_interval
      pantry_config.client_heartbeat_interval = 5
      assert_equal 5, pantry_config.client_heartbeat_interval
    end

    it "has an entry for the client's application" do
      pantry_config.client_application = "pantry"
      assert_equal "pantry", pantry_config.client_application
    end

    it "has an entry for the client's environment" do
      pantry_config.client_environment = "pantry"
      assert_equal "pantry", pantry_config.client_environment
    end

    it "has an entry for the client's identity" do
      pantry_config.client_identity = "pantry"
      assert_equal "pantry", pantry_config.client_identity
    end

    it "has an entry for the client's roles" do
      pantry_config.client_roles = ["roles"]
      assert_equal ["roles"], pantry_config.client_roles
    end

    it "can load values from a given YAML file" do
      config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "config.yml")
      pantry_config.load_file(config_file)

      assert_equal 600, pantry_config.client_heartbeat_interval
      assert_equal "pantry-test-1", pantry_config.client_identity
      assert_equal "pantry", pantry_config.client_application
      assert_equal "test", pantry_config.client_environment
      assert_equal %w(database application), pantry_config.client_roles
    end

    it "does not clobber certain values if config has set to nil" do
      config_file = File.join(File.dirname(__FILE__), "..", "fixtures", "empty.yml")
      pantry_config.load_file(config_file)

      assert_equal 300, pantry_config.client_heartbeat_interval
    end
  end

end
