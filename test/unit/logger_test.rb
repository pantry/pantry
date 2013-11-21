require 'unit/test_helper'

describe Pantry::Logger do

  after do
    # Unset global state caused by these tests
    Celluloid.logger = nil
  end

  it "is accessible through top level Pantry.logger" do
    assert_not_nil Pantry.logger
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

    logger = Pantry::Logger.new(config)

    assert Celluloid.logger.is_a?(::Syslog::Logger), "Celluloid logger not set properly"
  end

  it "forwards unknown messages to the celluloid logger" do
    logger = Pantry::Logger.new

    Celluloid.logger.expects(:info).with("Message!")

    logger.info("Message!")
  end

end
