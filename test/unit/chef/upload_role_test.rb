require 'unit/test_helper'

describe Pantry::Chef::UploadRole do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  describe "#prepare_message" do
    it "requires an application we're uploading for" do
      command = Pantry::Chef::UploadRole.new(fixture_path("roles/app.rb"))
      assert_raises Pantry::MissingOption do
        command.prepare_message(filter, {})
      end
    end

    it "sets the file name and contents in the message to the Server" do
      command = Pantry::Chef::UploadRole.new(fixture_path("roles/app.rb"))
      message = command.prepare_message(filter, {"application" => "pantry"})

      assert_equal "pantry", message.body[0]
      assert_equal "app.rb", message.body[1]
      assert_equal %|name "app"\ndescription "Application test role"\n|, message.body[2]
    end
  end

  describe "#perform" do
    fake_fs!

    it "writes out the file data to the appropriate location" do
      message = Pantry::Message.new
      message << "pantry"
      message << "filename.rb"
      message << "This is the content"

      command = Pantry::Chef::UploadRole.new
      command.perform(message)

      role_file = Pantry.root.join("applications", "pantry", "chef", "roles", "filename.rb")
      assert File.exists?(role_file), "Did not write out the file"
      assert_equal "This is the content", File.read(role_file)
    end
  end

end
