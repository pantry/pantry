require 'unit/test_helper'

describe Pantry::Chef::UploadEnvironment do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  describe "#to_message" do
    it "sets the file name and contents in the message to the Server" do
      command = Pantry::Chef::UploadEnvironment.new(fixture_path("environments/test.rb"))
      message = command.to_message

      assert_equal "test.rb", message.body[0]
      assert_equal %|name "test"\ndescription "Pantry test env"\n|, message.body[1]
    end
  end

  describe "#perform" do
    fake_fs!

    it "writes out the file data to the appropriate location" do
      message = Pantry::Message.new
      message << "filename.rb"
      message << "This is the content"

      command = Pantry::Chef::UploadEnvironment.new
      command.perform(message)

      environment_file = Pantry.root.join("chef", "environments", "filename.rb")
      assert File.exists?(environment_file), "Did not write out the file"
      assert_equal "This is the content", File.read(environment_file)
    end
  end

end
