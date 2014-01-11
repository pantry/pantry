require 'unit/test_helper'

describe Pantry::Chef::SendCookbooks do

  fake_fs!

  it "has a custom type" do
    assert_equal "Chef::SendCookbooks", Pantry::Chef::SendCookbooks.message_type
  end

  describe "#perform" do

    it "takes the list of receivers and builds senders, passing in the proper cookbook file" do
      message = Pantry::Message.new
      message << ["mini", "2.0.0", "receiver_ident", "file_uuid"]
      message << ["pantry", "1.0.0", "receiver_ident2", "file_uuid2"]

      cookbooks = [
        Pantry.root.join("chef", "cookbooks", "mini", "1.0.0.tgz"),
        Pantry.root.join("chef", "cookbooks", "mini", "2.0.0.tgz"),
        Pantry.root.join("chef", "cookbooks", "pantry", "1.0.0.tgz")
      ]

      cookbooks.each do|c|
        FileUtils.mkdir_p(File.dirname(c))
        FileUtils.touch(c)
      end

      server = mock
      server.expects(:send_file).with(
        Pantry.root.join("chef", "cookbooks", "mini", "2.0.0.tgz"),
        "receiver_ident",
        "file_uuid"
      )

      server.expects(:send_file).with(
        Pantry.root.join("chef", "cookbooks", "pantry", "1.0.0.tgz"),
        "receiver_ident2",
        "file_uuid2"
      )

      command = Pantry::Chef::SendCookbooks.new
      command.server = server
      command.perform(message)
    end

  end

end
