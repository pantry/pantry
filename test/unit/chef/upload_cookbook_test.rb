require 'unit/test_helper'

describe Pantry::Chef::UploadCookbook do

  let(:command) { Pantry::Chef::UploadCookbook.new }
  let(:filter) { Pantry::Communication::ClientFilter.new }

  describe "#prepare_message" do

    after do
      File.unlink(command.cookbook_tarball) if command.cookbook_tarball
    end

    it "figures out name and version of the requested cookbook" do
      message = command.prepare_message(
        filter, [File.expand_path("../../../fixtures/cookbooks/mini", __FILE__)]
      )

      assert_not_nil message, "Did not return a message"
      assert_equal "mini", message[:cookbook_name]
      assert_equal "1.0.0", message[:cookbook_version]
    end

    it "tars up the cookbook, noting the size and a checksum of the file" do
      message = command.prepare_message(
        filter, [File.expand_path("../../../fixtures/cookbooks/mini", __FILE__)]
      )

      assert message[:cookbook_size] > 0, "Did not calculate a size of the tarball"
      assert_not_nil message[:cookbook_checksum], "Did not calculate a checksum"

      assert_not_nil command.cookbook_tarball, "Did not save a pointer to the tarball"
      assert File.exists?(command.cookbook_tarball), "No tarball found on the file system"
    end

    it "errors out if no metadata file" do
      assert_raises Pantry::Chef::MissingMetadata do
        command.prepare_message(
          filter, [File.expand_path("../../../fixtures/cookbooks/bad", __FILE__)]
        )
      end
    end

    it "errors if it can't find the cookbook" do
      assert_raises Pantry::Chef::UnknownCookbook do
        command.prepare_message(
          filter, [File.expand_path("../../../fixtures/cookbooks/nonexist", __FILE__)]
        )
      end
    end

    # This is to be an error check that Chef itself doesn't do, but does completely fail
    # to run your cookbook if the metadata does not contain a name.
    it "errors if metadata does not contain name / version"

    it "marks in the Message if we want to force upload the current cookbook version"
  end

  describe "#perform" do

    let(:incoming_message) do
      m = command.to_message
      m[:cookbook_version]  = "1.0.0"
      m[:cookbook_name]     = "testing"
      m[:cookbook_size]     = 100
      m[:cookbook_checksum] = "123abc"
      m
    end

    it "ensures a place exists for the uploaded cookbook to go" do
      command.server_or_client = stub_everything
      command.message = incoming_message
      response = command.perform

      assert File.directory?(File.join(Pantry.config.data_dir, "chef", "cookbooks", "testing")),
        "Did not create directory for the testing cookbook"
    end

    it "responds successfully and fires off a file upload receiver" do
      server_mock = mock
      server_mock.expects(:receive_file).with(
        File.join(Pantry.config.data_dir, "chef", "cookbooks", "testing", "1.0.0.tgz"),
        100, "123abc"
      ).returns("abc123")

      command.server_or_client = server_mock
      command.message = incoming_message

      response = command.perform

      assert_equal [true, "abc123"], response
    end

    it "response with an error if a cookbook upload exists with that version" do
      FileUtils.mkdir_p File.join(Pantry.config.data_dir, "chef", "cookbooks", "testing")
      FileUtils.touch File.join(Pantry.config.data_dir, "chef", "cookbooks", "testing", "1.0.0.tgz")

      server = mock
      server.expects(:receive_file).never

      command.server_or_client = server
      command.message = incoming_message
      response = command.perform

      assert_equal [false, "Version 1.0.0 of cookbook testing already exists"], response
    end

    it "allows overwriting an existing upload if forced" do
      FileUtils.mkdir_p File.join(Pantry.config.data_dir, "chef", "cookbooks", "testing")
      FileUtils.touch File.join(Pantry.config.data_dir, "chef", "cookbooks", "testing", "1.0.0.tgz")

      server = mock(:receive_file => "a1b2c3")

      incoming_message[:cookbook_force_upload] = true

      command.server_or_client = server
      command.message = incoming_message
      response = command.perform

      assert_equal [true, "a1b2c3"], response
    end

  end

  describe "#handle_response" do

    it "triggers a file upload actor with the cookbook tarball and message UUID"

    it "fails out with a message and cleans up if the server response with an error"

  end

end
