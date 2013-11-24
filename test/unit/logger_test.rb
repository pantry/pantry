require 'unit/test_helper'

describe Pantry::Logger do

  let(:mock_logger) {
    logger = stub
    logger.stubs(:level=)
    logger
  }

  after do
    # Unset global state caused by these tests
    Celluloid.logger = nil
  end

  it "is accessible through top level Pantry.logger" do
    logger = Pantry.logger = Pantry::Logger.new
    assert_equal logger, Pantry.logger
  end

  it "sets the celluloid logger" do
    logger = Pantry::Logger.new

    assert Celluloid.logger.is_a?(::Logger), "Celluloid logger not set properly"
  end

  it "sets celluloid logger to a path if one given" do
    config = Pantry::Config.new
    config.log_to = File.expand_path("../../test.log", __FILE__)

    logger = Pantry::Logger.new(config)

    assert Celluloid.logger.is_a?(::Logger), "Celluloid logger not set properly"
  end

  it "sets the logger to go to Syslog if so configured" do
    config = Pantry::Config.new
    config.log_to = "syslog"

    Syslog::Logger.expects(:new).with("pantry").returns(mock_logger)

    logger = Pantry::Logger.new(config)
  end

  it "configures the Syslog program name if one given in the config" do
    config = Pantry::Config.new
    config.log_to = "syslog"
    config.syslog_program_name = "pantry-client"

    Syslog::Logger.expects(:new).with("pantry-client").returns(mock_logger)

    logger = Pantry::Logger.new(config)
  end

  it "sets the log's level according to config.log_level" do
    logger = Pantry::Logger.new

    assert_equal ::Logger::INFO, Celluloid.logger.level
  end

  it "allows symbols when setting log level" do
    config = Pantry::Config.new
    config.log_level = :warn

    logger = Pantry::Logger.new(config)

    assert_equal ::Logger::WARN, Celluloid.logger.level
  end

  it "forwards unknown messages to the celluloid logger" do
    logger = Pantry::Logger.new

    Celluloid.logger.expects(:info).with("Message!")

    logger.info("Message!")
  end

end
