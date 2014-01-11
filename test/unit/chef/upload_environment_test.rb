require 'unit/test_helper'

describe Pantry::Chef::UploadEnvironment do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  it "has a custom type" do
    assert_equal "Chef::UploadEnvironment", Pantry::Chef::UploadEnvironment.message_type
  end

  describe "#prepare_message" do
    it "requires an application we're uploading for" do
      command = Pantry::Chef::UploadEnvironment.new(fixture_path("environments/test.rb"))
      assert_raises Pantry::MissingOption do
        command.prepare_message(filter, {})
      end
    end

    it "sets the file name and contents in the message to the Server" do
      command = Pantry::Chef::UploadEnvironment.new(fixture_path("environments/test.rb"))
      message = command.prepare_message(filter, {"application" => "pantry"})

      assert_equal "pantry", message.body[0]
      assert_equal "test.rb", message.body[1]
      assert_equal %|name "test"\ndescription "Pantry test env"\n|, message.body[2]
    end
  end

  describe "#perform" do
    fake_fs!

    it "writes out the file data to the appropriate location" do
      message = Pantry::Message.new
      message << "pantry"
      message << "filename.rb"
      message << "This is the content"

      command = Pantry::Chef::UploadEnvironment.new
      command.perform(message)

      environment_file = Pantry.root.join(
        "applications", "pantry", "chef", "environments", "filename.rb")
      assert File.exists?(environment_file), "Did not write out the file"
      assert_equal "This is the content", File.read(environment_file)
    end
  end

end
