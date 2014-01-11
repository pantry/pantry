require 'unit/test_helper'

describe Pantry::Chef::UploadCookbook do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  def build_command(cookbook_name)
    @command ||=
      Pantry::Chef::UploadCookbook.new(fixture_path("cookbooks/#{cookbook_name}"))
  end

  it "has a custom type" do
    assert_equal "Chef::UploadCookbook", Pantry::Chef::UploadCookbook.message_type
  end

  describe "#prepare_message" do

    after do
      File.unlink(@command.cookbook_tarball) if @command && @command.cookbook_tarball
    end

    it "figures out name and version of the requested cookbook" do
      command = build_command("mini")
      message = command.prepare_message(filter, {})

      assert_not_nil message, "Did not return a message"
      assert_equal "mini", message[:cookbook_name]
      assert_equal "1.0.0", message[:cookbook_version]
    end

    it "tars up the cookbook, noting the size and a checksum of the file" do
      command = build_command("mini")
      message = command.prepare_message(filter, {})

      assert message[:cookbook_size] > 0, "Did not calculate a size of the tarball"
      assert_not_nil message[:cookbook_checksum], "Did not calculate a checksum"

      assert_not_nil command.cookbook_tarball, "Did not save a pointer to the tarball"
      assert File.exists?(command.cookbook_tarball), "No tarball found on the file system"
    end

    it "errors out if no metadata file" do
      assert_raises Pantry::Chef::MissingMetadata do
        command = build_command("bad")
        command.prepare_message(filter, {})
      end
    end

    it "errors if it can't find the cookbook" do
      assert_raises Pantry::Chef::UnknownCookbook do
        command = build_command("nonexist")
        command.prepare_message(filter, {})
      end
    end

    # This is to be an error check that Chef itself doesn't do, but does completely fail
    # to run your cookbook if the metadata does not contain a name.
    it "errors if metadata does not contain name / version"

    it "marks in the Message if we want to force upload the current cookbook version" do
      command = build_command("mini")
      message = command.prepare_message(filter, {'force' => true})

      assert message[:cookbook_force_upload], "Did not mark as a force upload"
    end
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

    let(:command) { build_command("mini") }

    let(:receiver_info) {
      stub(
        :uuid => "abc123",
        :receiver_identity => "receiver",
        :on_complete => nil
      )
    }

    it "ensures a place exists for the uploaded cookbook to go" do
      command.server_or_client = stub(:receive_file => receiver_info)
      response = command.perform(incoming_message)

      assert File.directory?(Pantry.root.join("chef", "cookbooks", "testing")),
        "Did not create directory for the testing cookbook"
    end

    it "responds successfully and fires off a file upload receiver" do
      server_mock = mock
      server_mock.expects(:receive_file).with(100, "123abc").returns(receiver_info)

      command.server_or_client = server_mock

      response = command.perform(incoming_message)

      assert_equal [true, "receiver", "abc123"], response
    end

    it "response with an error if a cookbook upload exists with that version" do
      FileUtils.mkdir_p Pantry.root.join("chef", "cookbooks", "testing")
      FileUtils.touch Pantry.root.join("chef", "cookbooks", "testing", "1.0.0.tgz")

      server = mock
      server.expects(:receive_file).never

      command.server_or_client = server
      response = command.perform(incoming_message)

      assert_equal [false, "Version 1.0.0 of cookbook testing already exists"], response
    end

    it "allows overwriting an existing upload if forced" do
      FileUtils.mkdir_p Pantry.root.join("chef", "cookbooks", "testing")
      FileUtils.touch Pantry.root.join("chef", "cookbooks", "testing", "1.0.0.tgz")

      server = mock(:receive_file => receiver_info)

      incoming_message[:cookbook_force_upload] = true

      command.server_or_client = server
      response = command.perform(incoming_message)

      assert_equal [true, "receiver", "abc123"], response
    end

  end

  describe "#receive_response" do

    let(:command) { build_command("mini") }

    it "triggers a file upload actor with the cookbook tarball and message UUID" do
      client = mock
      client.expects(:send_file).with do |file, receiver_uuid|
        assert File.exists?(file), "Did not find the file"
        assert_equal "abc123", receiver_uuid
      end.returns(mock(:wait_for_finish))

      command.server_or_client = client
      command.prepare_message(filter, {})

      response_message = Pantry::Message.new
      response_message.body << "true"
      response_message.body << "abc123"

      command.receive_response(response_message)
    end

    it "fails out with a message and cleans up if the server response with an error" do
      client = mock
      client.expects(:send_file).never

      command.server_or_client = client
      command.prepare_message(filter, {})

      response_message = Pantry::Message.new
      response_message.body << "false"
      response_message.body << "Unable to Upload Reason"

      command.progress_listener = mock
      command.progress_listener.expects(:error).with("Unable to Upload Reason")
      command.progress_listener.expects(:finished)

      command.receive_response(response_message)
    end

  end

end
