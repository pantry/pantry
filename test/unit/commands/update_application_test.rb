require 'unit/test_helper'

describe Pantry::Commands::UpdateApplication do
  let(:command) { Pantry::Commands::UpdateApplication.new }

  fake_fs!

  describe "#perform" do
    it "takes contents of the message and writes out a new config file for the application" do
      message = Pantry::Message.new
      message << "pantry"
      message << {name: "pantry", enviornment: "test"}.to_yaml

      assert command.perform(message)

      assert File.exists?(Pantry.root.join("applications", "pantry", "config.yml")),
        "Did not write out the new config file"
    end

    it "ignores file content that's not valid YAML" do
      message = Pantry::Message.new
      message << "pantry"
      message << "---\nthis: that\n<> { not valid yaml zomg }"

      response = command.perform(message)

      assert_false response[0]
      assert_false File.exists?(Pantry.root.join("applications", "pantry", "config.yml")),
        "Wrote out an invalid config file"
    end

    it "creates a backup of the file being overwritten"
  end

end
