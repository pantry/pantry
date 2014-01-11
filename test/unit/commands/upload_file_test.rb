require 'unit/test_helper'

describe Pantry::Commands::UploadFile do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  class MyUploader < Pantry::Commands::UploadFile
    def upload_directory(application)
      Pantry.root.join("upload", application)
    end
  end

  describe "#prepare_message" do
    it "requires an application we're uploading for" do
      command = MyUploader.new(fixture_path("file_to_upload"))
      assert_raises Pantry::MissingOption do
        command.prepare_message(filter, {})
      end
    end

    it "sets the file name and contents in the message to the Server" do
      command = MyUploader.new(fixture_path("file_to_upload"))
      message = command.prepare_message(filter, {"application" => "pantry"})

      assert_equal "pantry", message.body[0]
      assert_equal "file_to_upload", message.body[1]
      assert_equal %|Hello\nPantry\n!\n|, message.body[2]
    end
  end

  describe "#perform" do
    fake_fs!

    it "writes out the file data to the appropriate location" do
      message = Pantry::Message.new
      message << "pantry"
      message << "filename.rb"
      message << "This is the content"

      command = MyUploader.new
      command.perform(message)

      uploaded_file = Pantry.root.join("upload", "pantry", "filename.rb")
      assert File.exists?(uploaded_file), "Did not write out the file"
      assert_equal "This is the content", File.read(uploaded_file)
    end
  end

end
