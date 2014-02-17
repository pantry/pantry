require 'unit/test_helper'

describe Pantry::Chef::UploadCookbook do

  mock_ui!

  def build_command(cookbook_name)
    @command ||=
      Pantry::Chef::UploadCookbook.new(fixture_path("cookbooks/#{cookbook_name}"))
  end

  describe "#prepare_message" do

    after do
      File.unlink(@command.cookbook_tarball) if @command && @command.cookbook_tarball
    end

    it "figures out name of the requested cookbook" do
      command = build_command("mini")
      message = command.prepare_message({})

      assert_not_nil message, "Did not return a message"
      assert_equal "mini", message[:cookbook_name]
    end

    it "tars up the cookbook, noting the size and a checksum of the file" do
      command = build_command("mini")
      message = command.prepare_message({})

      assert message[:cookbook_size] > 0, "Did not calculate a size of the tarball"
      assert_not_nil message[:cookbook_checksum], "Did not calculate a checksum"

      assert_not_nil command.cookbook_tarball, "Did not save a pointer to the tarball"
      assert File.exists?(command.cookbook_tarball), "No tarball found on the file system"
    end

    it "errors out if no metadata file" do
      assert_raises Pantry::Chef::MissingMetadata do
        command = build_command("bad")
        command.prepare_message({})
      end
    end

    it "errors if it can't find the cookbook" do
      assert_raises Pantry::Chef::UnknownCookbook do
        command = build_command("nonexist")
        command.prepare_message({})
      end
    end
  end

  describe "#perform" do

    let(:incoming_message) do
      m = command.to_message
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

      assert File.directory?(Pantry.root.join("chef", "cookbooks")),
        "Did not create directory for the testing cookbook"
    end

    it "responds successfully and fires off a file upload receiver" do
      server_mock = mock
      server_mock.expects(:receive_file).with(100, "123abc").returns(receiver_info)

      command.server_or_client = server_mock

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
      command.prepare_message({})

      response_message = Pantry::Message.new
      response_message.body << "true"
      response_message.body << "abc123"

      command.receive_response(response_message)
    end

    it "fails out with a message and cleans up if the server response with an error" do
      client = mock
      client.expects(:send_file).never

      command.server_or_client = client
      command.prepare_message({})

      response_message = Pantry::Message.new
      response_message << "false"
      response_message << "Unable to Upload Reason"

      command.receive_response(response_message)

      assert_match /ERROR: Unable to Upload Reason/, stdout
    end

  end

end
