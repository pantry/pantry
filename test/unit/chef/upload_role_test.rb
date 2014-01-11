require 'unit/test_helper'

describe Pantry::Chef::UploadRole do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  describe "#to_message" do
    it "sets the file name and contents in the message to the Server" do
      command = Pantry::Chef::UploadRole.new(fixture_path("roles/staging.rb"))
      message = command.to_message

      assert_equal "staging.rb", message.body[0]
      assert_equal %|name "Staging"\ndescription "Staging test role"\n|, message.body[1]
    end
  end

  describe "#perform" do
    fake_fs!

    it "writes out the file data to the appropriate location" do
      message = Pantry::Message.new
      message << "filename.rb"
      message << "This is the content"

      command = Pantry::Chef::UploadRole.new
      command.perform(message)

      role_file = Pantry.root.join("chef", "roles", "filename.rb")
      assert File.exists?(role_file), "Did not write out the file"
      assert_equal "This is the content", File.read(role_file)
    end
  end

end
