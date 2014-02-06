require 'unit/test_helper'

describe Pantry::Commands::EditApplication do
  let(:command) { Pantry::Commands::EditApplication.new }
  let(:filter) { Pantry::Communication::ClientFilter.new }

  fake_fs!

  describe "#prepare_message" do
    it "requires an application" do
      assert_raises(Pantry::MissingOption) do
        command.prepare_message(filter, {})
      end
    end

    it "puts the application requested in the message" do
      message = command.prepare_message(filter, {application: "pantry"})
      assert_equal "pantry", message.body[0]
    end
  end

  describe "#perform" do
    let(:edit_message) do
      Pantry::Message.new.tap do |msg|
        msg << "pantry"
      end
    end

    it "returns the configuration of the given application" do
      config_file = Pantry.root.join("applications", "pantry", "config.yml")
      FileUtils.mkdir_p(File.dirname(config_file))
      File.open(config_file, "w+") do |f|
        f.write({"some" => "config"}.to_yaml)
      end

      response = command.perform(edit_message)
      assert_equal "---\nsome: config\n", response[0]
    end

    it "returns a new YAML config if no file exist for the application" do
      response = command.perform(edit_message)
      assert_equal "---\nname: pantry\n", response[0]
    end
  end

  describe "#receive_response" do
    it "lets the user edit the file and uploads when successful" do
      orig_config_body = {name: "pantry"}.to_yaml
      new_config_body = {name: "pantry", config: false}.to_yaml

      response = Pantry::Message.new
      response << orig_config_body

      Pantry::FileEditor.any_instance.expects(:edit).
        with(orig_config_body, :yaml).returns(new_config_body)

      command.expects(:send_request!).with do |message|
        assert_equal "pantry", message.body[0]
        assert_equal new_config_body, message.body[1]
      end

      command.prepare_message(filter, {application: "pantry"})
      command.receive_response(response)

      assert command.finished?, "Command was not finished"
    end

    it "doesn't send the Update command if file contents did not change" do
      config_body = {name: "pantry"}.to_yaml

      response = Pantry::Message.new
      response << config_body

      Pantry::FileEditor.any_instance.expects(:edit).returns(config_body)

      command.expects(:send_request!).never

      command.prepare_message(filter, {application: "pantry"})
      command.receive_response(response)
    end
  end

end
